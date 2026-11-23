"""Every query runs on the hand-made fixture and returns the expected columns.

A few results are also checked against values worked out by hand (or recomputed here in
plain Python), so a query that runs but answers wrongly still fails.
"""

from __future__ import annotations

import csv
from decimal import Decimal
from pathlib import Path

import pytest

from sql_analytics.run import analysis_files, build_database, run_query

FIXTURE = Path(__file__).parent / "fixture"

EXPECTED_COLUMNS = {
    "02_data_quality": ["check_id", "check_name", "value", "passed"],
    "03_headline_kpis": ["total_orders", "total_pizzas", "total_revenue", "avg_order_value",
                         "avg_pizzas_per_order", "days_open", "avg_orders_per_day",
                         "avg_revenue_per_day", "first_day", "last_day"],
    "10_menu_pareto": ["revenue_rank", "pizza_name", "category", "pizzas_sold", "revenue",
                       "revenue_share_pct", "cumulative_share_pct", "in_top_80pct"],
    "11_menu_cut_candidates": ["pizza_name", "category", "pizzas_sold", "revenue",
                               "avg_price_paid", "orders_containing", "revenue_quartile",
                               "volume_quartile", "recommendation"],
    "20_staffing_hour_weekday": ["weekday_num", "weekday", "hour", "orders", "pizzas",
                                 "open_days", "avg_orders_per_day", "avg_pizzas_per_day"],
    "30_size_mix": ["size", "pizza_types_on_menu", "pizzas_sold", "revenue",
                    "volume_share_pct", "revenue_share_pct", "avg_price_paid",
                    "avg_menu_price"],
    "40_weekly_growth": ["week_start", "days_open", "orders", "revenue", "prev_week_revenue",
                         "wow_change_pct", "full_week"],
    "41_daily_rolling_7d": ["order_date", "orders", "revenue", "open",
                            "rolling_7d_avg_revenue", "rolling_7d_avg_orders"],
    "50_market_basket": ["pizza_a", "pizza_b", "orders_together", "support_pct",
                         "confidence_a_to_b_pct", "confidence_b_to_a_pct", "lift"],
    "60_seasonality_monthly": ["month", "month_name", "days_open", "orders", "pizzas",
                               "revenue", "revenue_per_open_day", "index_vs_avg",
                               "rank_per_day"],
    "70_aov_drivers": ["driver", "segment", "orders", "order_share_pct", "revenue",
                       "revenue_share_pct", "avg_order_value", "avg_pizzas"],
    "80_ingredient_demand": ["ingredient", "pizza_types_using", "pizzas_sold_containing",
                             "single_pizza_ingredient"],
}


@pytest.fixture(scope="module")
def con():
    connection = build_database(FIXTURE)
    yield connection
    connection.close()


def result(con, stem):
    path = next(p for p in analysis_files() if p.stem == stem)
    columns, rows = run_query(con, path)
    return [dict(zip(columns, row)) for row in rows]


def _csv(name):
    with (FIXTURE / name).open(encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def test_every_query_file_is_covered():
    assert {p.stem for p in analysis_files()} == set(EXPECTED_COLUMNS)


@pytest.mark.parametrize("stem", sorted(EXPECTED_COLUMNS))
def test_query_runs_and_returns_expected_columns(con, stem):
    path = next(p for p in analysis_files() if p.stem == stem)
    columns, rows = run_query(con, path)
    assert columns == EXPECTED_COLUMNS[stem]
    assert rows, f"{stem} returned no rows on the fixture"


@pytest.mark.parametrize("path", analysis_files(), ids=lambda p: p.name)
def test_query_file_opens_with_question_reason_and_technique(path):
    head = path.read_text(encoding="utf-8")[:1200]
    for marker in ("-- Question:", "-- Why a manager cares:", "-- Technique:"):
        assert marker in head, f"{path.name} is missing '{marker}'"


def test_data_quality_checks_all_pass(con):
    rows = result(con, "02_data_quality")
    assert all(r["passed"] for r in rows), [r for r in rows if not r["passed"]]
    counts = {r["check_name"]: r["value"] for r in rows}
    assert counts["orders loaded"] == 12
    assert counts["order lines loaded"] == 19


def test_headline_kpis_match_plain_python(con):
    prices = {r["pizza_id"]: Decimal(r["price"]) for r in _csv("pizzas.csv")}
    lines = _csv("order_details.csv")
    revenue = sum(prices[r["pizza_id"]] * int(r["quantity"]) for r in lines)
    kpi = result(con, "03_headline_kpis")[0]
    assert kpi["total_orders"] == 12
    assert kpi["total_pizzas"] == sum(int(r["quantity"]) for r in lines) == 23
    assert kpi["total_revenue"] == revenue
    assert kpi["days_open"] == 11                 # two orders on 1 Jan


def test_pareto_running_share_ends_at_100(con):
    rows = result(con, "10_menu_pareto")
    shares = [r["cumulative_share_pct"] for r in rows]
    assert shares == sorted(shares)
    assert float(shares[-1]) == pytest.approx(100.0)
    assert rows[0]["in_top_80pct"] is True


def test_market_basket_counts_each_pair_once(con):
    top = result(con, "50_market_basket")[0]
    # Margherita and Pepperoni share orders 2, 3, 5, 9 and 11.
    assert (top["pizza_a"], top["pizza_b"]) == ("The Fixture Margherita Pizza",
                                               "The Fixture Pepperoni Pizza")
    assert top["orders_together"] == 5


def test_rolling_window_uses_calendar_days(con):
    rows = result(con, "41_daily_rolling_7d")
    assert len(rows) == 34                      # 1 Jan to 3 Feb, closed days included
    assert sum(not r["open"] for r in rows) == 23


def test_week_over_week_skips_partial_weeks(con):
    rows = result(con, "40_weekly_growth")
    assert all(r["wow_change_pct"] is None for r in rows if not r["full_week"])


def test_size_mix_shares_sum_to_100(con):
    rows = result(con, "30_size_mix")
    assert [r["size"] for r in rows] == ["S", "M", "L", "XL"]
    assert float(sum(r["revenue_share_pct"] for r in rows)) == pytest.approx(100, abs=0.05)


def test_aov_drivers_split_every_order_twice(con):
    rows = result(con, "70_aov_drivers")
    for driver in ("pizzas in order", "time of day"):
        assert sum(r["orders"] for r in rows if r["driver"] == driver) == 12
