"""Shared deterministic simulation used by the notebook and command-line build."""
import csv
import hashlib
from pathlib import Path

import numpy as np

U64_MAX = 2**64 - 1



def integer_in_range(value: int, name: str, low: int, high: int | None = None) -> int:
    """Validates that the given value is an integer within the specified range.
    Args:
        value (int): The value to validate.
        name (str): The name of the variable being validated (used in error messages).
        low (int): The lower bound of the valid range (inclusive).
        high (int | None): The upper bound of the valid range (inclusive). If None, no upper bound is enforced.
    Raises:
        TypeError: If the value is not an integer.
        ValueError: If the value is outside the specified range.
    Returns:
        int: The validated integer value.
    """
    if isinstance(value, (bool, np.bool_)) or not isinstance(value, int):
        raise TypeError(f"{name} must be an integer")

    if value < low or (high is not None and value > high):
        raise ValueError(f"{name} must be in the range [{low}, {high}]")

    return value


def encode(trial_id: int, counter: int) -> bytes:
    """Encode (trial_id, counter) as two unsigned 64-bit integers in big-endian order
    Args:
        trial_id (int): The trial ID to encode.
        counter (int): The counter value to encode.
    Raises:
        TypeError: If trial_id or counter is not an integer.
        ValueError: If trial_id or counter is outside the range of a 64-bit unsigned integer.
    Returns:
        bytes: A byte string representing the encoded (trial_id, counter) pair.
    """
    trial_id = integer_in_range(trial_id, "trial_id", 0, U64_MAX)
    counter = integer_in_range(counter, "counter", 0, U64_MAX)

    return trial_id.to_bytes(8, byteorder="big") + counter.to_bytes(8, byteorder="big")


def truncate_sha_256(message: bytes, bits: int) -> int:
    """Return the first leading 1-256 bits of the SHA-256 hash of the given message as a nonnegative integer.
    Args:
        message (bytes): The input message to hash.
        bits (int): The number of leading bits to return from the hash (1-256).
    Raises:
        ValueError: If bits is not in the range [1, 256].
    Returns:
        int: The first leading bits of the SHA-256 hash as a nonnegative integer.
    """
    if not isinstance(message, (bytes, bytearray)):
        raise TypeError("message must be bytes or bytearray")

    bits = integer_in_range(bits, "bits", 1, 256)
    byte_count = (
        bits + 7
    ) // 8  # Calculate the number of bytes needed to cover the specified bits
    leading_bytes = hashlib.sha256(message).digest()[:byte_count]
    unused_bits = 8 * byte_count - bits
    return int.from_bytes(leading_bytes, byteorder="big") >> unused_bits


def collision_search(trial_id: int, bits: int, *, trace: bool = False) -> int:
    """Count draws through the first repeated prefix, optionally showing each draw.
    Args:
        trial_id (int): The ID of the trial.
        bits (int): The number of bits to consider for the prefix.
        trace (bool, optional): Whether to show each draw. Defaults to False.
    Raises:
        OverflowError: If the 64-bit counter is exhausted before finding a repeat.
    Returns:
        int: The number of draws until the first repeated prefix is found.
    """
    bits = integer_in_range(bits, "bits", 1, 256)
    last_counter = min(2**bits + 1, U64_MAX)
    first_seen_at: dict[int, int] = {}  # seen prefixes starts empty

    if trace:
        print("Draw Prefix Observation")

    for counter in range(1, last_counter + 1):
        message = encode(trial_id, counter)
        prefix = truncate_sha_256(message, bits)
        previous = first_seen_at.get(prefix)  # Check if we've seen this prefix before

        if trace:
            digits = (bits + 3) // 4
            label = format(prefix, f"0{digits}x")
            note = "new" if previous is None else f"matches draw {previous}"
            print(f"{counter:>4} {label:>6} {note}")

        if previous is not None:  # We have seen this prefix before (a collision)
            return counter
        first_seen_at[prefix] = counter # Else record the first occurrence of this prefix (a survival)

    raise OverflowError("Exhausted the 64-bit counter before finding a repeat.")  # violates experimental assumption (T <= 2^bits)


def experiment_driver(trials: int, bits: int, master_seed: int) -> list[dict]:
    """Return one row per completed trial in collection order.
    Args:
        trials (int): The number of trials to run.
        bits (int): The number of bits to consider for the prefix.
        master_seed (int): The master seed for the random number generator.
    Raises:
        TypeError: If trials, bits, or master_seed is not an integer.
        ValueError: If trials is less than 1, bits is not in the range [1, 256], or master_seed is negative.
    Returns:
        list[dict]: A list of dictionaries, each representing a trial with its parameters and results.
    """
    trials = integer_in_range(trials, "trials", 1, 2**63)
    bits = integer_in_range(bits, "bits", 1, 256)
    master_seed = integer_in_range(master_seed, "master_seed", 0)

    rng = np.random.Generator(np.random.PCG64([master_seed, bits]))
    used_ids: set[int] = set()
    rows = []

    while len(rows) < trials:
        trial_id = int(rng.integers(0, 2**63, dtype=np.uint64))
        if trial_id in used_ids:
            continue
        used_ids.add(trial_id)
        rows.append(
            {
                "trial": len(rows) + 1,
                "trial_id": str(trial_id),
                "bits": bits,
                "master_seed": str(master_seed),
                "T": collision_search(trial_id, bits),
            }
        )
    return rows


def collision_probability(k: int, outcomes: int) -> float:
    """Return the probability of at least one collision in k draws from outcomes possibilities.
    Args:
        k (int): The number of draws.
        outcomes (int): The number of possible outcomes.
    Raises:
        TypeError: If k or outcomes is not an integer.
        ValueError: If k is negative or greater than outcomes, or if outcomes is less than 1.
    Returns:
        float: The probability of at least one collision.
    """
    k = integer_in_range(k, "k", 0, outcomes)
    outcomes = integer_in_range(outcomes, "outcomes", 1)
    if k > outcomes:
        return 1.0
    used = np.arange(k, dtype=np.float64)
    log_survival = np.log1p(-used / float(outcomes)).sum()
    return float(-np.expm1(log_survival))


def save_trials(dataset: list[dict], output_dir: Path = Path("build/data")) -> Path:
    first = dataset[0]
    filename = f"trials_b{first['bits']}_n{len(dataset)}_seed{first['master_seed']}.csv"
    path = Path(output_dir) / filename
    path.parent.mkdir(parents=True, exist_ok=True)

    with path.open("w", newline="", encoding="utf-8") as stream:
        fields = ["trial", "trial_id", "bits", "master_seed", "T"]
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(dataset)
    return path
