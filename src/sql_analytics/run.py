"""Build the DuckDB database, run every analysis query, write results and charts.

    python -m sql_analytics.run                      # real data in data/raw
    python -m sql_analytics.run --data-dir tests/fixture --no-charts
"""

from __future__ import annotations

import argparse
import csv
import sys
import time
from pathlib import Path
from typing import Any

import duckdb

ROOT = Path(__file__).resolve().parents[2]
SQL_DIR = ROOT / "sql"
SETUP_FILES = ("00_schema.sql", "01_load.sql")


def analysis_files(sql_dir: Path = SQL_DIR) -> list[Path]:
    """Every numbered .sql file except the schema and load steps, in file order."""
    return sorted(p for p in sql_dir.glob("[0-9][0-9]_*.sql") if p.name not in SETUP_FILES)


def build_database(data_dir: Path, db_path: str = ":memory:") -> duckdb.DuckDBPyConnection:
    """Create the schema and load the four CSVs from data_dir."""
    data_dir = Path(data_dir).resolve()
    missing = [f for f in ("orders.csv", "order_details.csv", "pizzas.csv", "pizza_types.csv")
               if not (data_dir / f).exists()]
    if missing:
        raise FileNotFoundError(
            f"Missing {missing} in {data_dir}. Run `python scripts/download_data.py` first."
        )
    con = duckdb.connect(db_path)
    con.execute((SQL_DIR / "00_schema.sql").read_text(encoding="utf-8"))
    load_sql = (SQL_DIR / "01_load.sql").read_text(encoding="utf-8")
    con.execute(load_sql.replace("{{DATA_DIR}}", data_dir.as_posix()))
    return con


def run_query(con: duckdb.DuckDBPyConnection, path: Path) -> tuple[list[str], list[tuple]]:
    """Run one analysis file and return (column names, rows)."""
    cur = con.execute(Path(path).read_text(encoding="utf-8"))
    columns = [d[0] for d in cur.description]
    return columns, cur.fetchall()


def _cell(value: Any) -> Any:
    if isinstance(value, bool):
        return "true" if value else "false"
    if value is None:
        return ""
    return value


def write_csv(path: Path, columns: list[str], rows: list[tuple]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.writer(fh)
        writer.writerow(columns)
        writer.writerows([_cell(v) for v in row] for row in rows)


def run_all(data_dir: Path, results_dir: Path, db_path: str = ":memory:") -> dict[str, Path]:
    con = build_database(data_dir, db_path)
    written: dict[str, Path] = {}
    for sql_file in analysis_files():
        start = time.perf_counter()
        columns, rows = run_query(con, sql_file)
        out = results_dir / f"{sql_file.stem}.csv"
        write_csv(out, columns, rows)
        written[sql_file.stem] = out
        print(f"  {sql_file.name:<32} {len(rows):>5} rows  {1000 * (time.perf_counter() - start):6.1f} ms")
    con.close()
    return written


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Run every analysis query.")
    parser.add_argument("--data-dir", type=Path, default=ROOT / "data" / "raw")
    parser.add_argument("--results", type=Path, default=ROOT / "results")
    parser.add_argument("--reports", type=Path, default=ROOT / "reports")
    parser.add_argument("--db", default=":memory:", help="DuckDB file to keep, e.g. pizza.duckdb")
    parser.add_argument("--no-charts", action="store_true")
    args = parser.parse_args(argv)

    print(f"Loading {args.data_dir}")
    run_all(args.data_dir, args.results, args.db)
    if not args.no_charts:
        from sql_analytics import charts  # imported late so tests do not need matplotlib

        for path in charts.render_all(args.results, args.reports):
            print(f"  chart {path.name}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
