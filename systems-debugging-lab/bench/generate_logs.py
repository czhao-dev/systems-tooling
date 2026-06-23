#!/usr/bin/env python3
"""Generates synthetic HTTP-access-style log files for LogForge.

All output is randomly generated; no real client IPs, paths, or timing data
are used.
"""

import argparse
import random
from datetime import datetime, timedelta, timezone

METHODS = ["GET", "GET", "GET", "POST", "PUT", "DELETE"]
PATHS = [
    "/api/users",
    "/api/orders",
    "/api/products",
    "/api/login",
    "/api/logout",
    "/api/cart",
    "/api/search",
    "/api/health",
]
STATUSES = [200] * 80 + [301] * 5 + [400] * 4 + [401] * 4 + [404] * 5 + [500] * 2


def random_ip(rng: random.Random) -> str:
    return f"192.168.{rng.randint(0, 5)}.{rng.randint(1, 254)}"


def generate(records: int, seed: int):
    rng = random.Random(seed)
    timestamp = datetime(2026, 6, 19, 10, 0, 0, tzinfo=timezone.utc)
    for _ in range(records):
        timestamp += timedelta(seconds=rng.randint(0, 2))
        status = rng.choice(STATUSES)
        latency = rng.randint(5, 50) if status < 400 else rng.randint(20, 900)
        yield (
            f"{timestamp.strftime('%Y-%m-%dT%H:%M:%SZ')} "
            f"{random_ip(rng)} {rng.choice(METHODS)} {rng.choice(PATHS)} "
            f"{status} {latency}ms"
        )


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--records", type=int, required=True, help="number of log lines to generate")
    parser.add_argument("--output", required=True, help="output file path")
    parser.add_argument("--seed", type=int, default=42, help="random seed for reproducibility")
    args = parser.parse_args()

    with open(args.output, "w") as f:
        for line in generate(args.records, args.seed):
            f.write(line + "\n")

    print(f"Wrote {args.records} synthetic log records to {args.output}")


if __name__ == "__main__":
    main()
