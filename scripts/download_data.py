"""Download the Pizza Place Sales dataset from Maven Analytics' Data Playground.

Source page: https://mavenanalytics.io/data-playground/pizza-place-sales
Licence (as stated on that page): Public Domain. Original source: Rdatasets.

Usage:
    python scripts/download_data.py            # skip if the four CSVs are already present
    python scripts/download_data.py --force    # download again
"""

from __future__ import annotations

import argparse
import io
import sys
import urllib.request
import zipfile
from pathlib import Path

URL = "https://maven-datasets.s3.amazonaws.com/Pizza+Place+Sales/Pizza+Place+Sales.zip"
FILES = ("orders.csv", "order_details.csv", "pizzas.csv", "pizza_types.csv")
DEST = Path(__file__).resolve().parent.parent / "data" / "raw"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--force", action="store_true", help="download even if files exist")
    parser.add_argument("--dest", type=Path, default=DEST, help="folder for the CSVs")
    args = parser.parse_args()

    dest: Path = args.dest
    dest.mkdir(parents=True, exist_ok=True)
    if not args.force and all((dest / f).exists() for f in FILES):
        print(f"Data already present in {dest}; use --force to download again.")
        return 0

    print(f"Downloading {URL}")
    req = urllib.request.Request(URL, headers={"User-Agent": "sql-analytics-downloader"})
    with urllib.request.urlopen(req, timeout=60) as resp:
        payload = resp.read()

    with zipfile.ZipFile(io.BytesIO(payload)) as zf:
        wanted = {Path(n).name: n for n in zf.namelist() if Path(n).name in FILES}
        missing = set(FILES) - set(wanted)
        if missing:
            print(f"Archive is missing: {sorted(missing)}", file=sys.stderr)
            return 1
        for name, member in wanted.items():
            (dest / name).write_bytes(to_utf8(zf.read(member)))
            print(f"  wrote {dest / name}")
    return 0


def to_utf8(raw: bytes) -> bytes:
    """The published pizza_types.csv is Windows-1252 (one curly quote in "'Nduja").

    DuckDB, MySQL and PostgreSQL all read UTF-8 by default, so every file is stored as UTF-8.
    """
    try:
        raw.decode("utf-8")
        return raw
    except UnicodeDecodeError:
        return raw.decode("cp1252").encode("utf-8")


if __name__ == "__main__":
    raise SystemExit(main())
