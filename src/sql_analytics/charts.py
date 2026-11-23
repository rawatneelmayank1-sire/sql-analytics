"""Static README charts drawn from results/*.csv.

Every chart is rendered twice, <name>.png (light) and <name>-dark.png (dark), from one
set of colour tokens. Palette checked with a CVD and contrast validator: see README.
"""

from __future__ import annotations

import csv
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.colors import LinearSegmentedColormap  # noqa: E402
from matplotlib.patches import Patch  # noqa: E402
from matplotlib.ticker import FuncFormatter  # noqa: E402

STYLE = Path(__file__).with_name("chart.mplstyle")

# Colour tokens. Taken from the subject: tomato sauce (accent), charred crust (ink),
# flour (light surface), a cooled oven (dark surface), ash (context marks).
TOKENS = {
    "light": {
        "surface": "#FCFBF9", "ink": "#221E1C", "ink_2": "#5A524D", "muted": "#766D67",
        "grid": "#E6E1DC", "axis": "#C9C1BA", "accent": "#B4362A", "context": "#958A82",
        "heat": ["#FBEDE9", "#F3C9BF", "#E39A89", "#CC6A56", "#B4362A", "#74201A"],
        "ordinal": ["#E49B8B", "#D27563", "#BF4F3D", "#9E3226", "#74201A"],
    },
    "dark": {
        "surface": "#1E1A18", "ink": "#F1ECE8", "ink_2": "#C9C0B9", "muted": "#A2988F",
        "grid": "#34302D", "axis": "#4A4440", "accent": "#E0604F", "context": "#6E655F",
        "heat": ["#2A211E", "#5A2219", "#8A3426", "#C04A39", "#E0604F", "#F7B9AB"],
        "ordinal": ["#9A3A2C", "#C04A39", "#DD6552", "#EE8C79", "#F7B9AB"],
    },
}


def _read(results: Path, name: str) -> list[dict[str, str]]:
    with (results / f"{name}.csv").open(encoding="utf-8") as fh:
        return list(csv.DictReader(fh))


def _theme(mode: str) -> dict:
    t = TOKENS[mode]
    return {
        "figure.facecolor": t["surface"], "axes.facecolor": t["surface"],
        "savefig.facecolor": t["surface"], "text.color": t["ink"],
        "axes.labelcolor": t["ink_2"], "axes.edgecolor": t["axis"],
        "axes.titlecolor": t["ink"], "xtick.color": t["muted"], "ytick.color": t["muted"],
        "xtick.labelcolor": t["ink_2"], "ytick.labelcolor": t["ink_2"],
        "grid.color": t["grid"], "legend.labelcolor": t["ink_2"],
    }


def _subtitle(ax, text: str, t: dict) -> None:
    ax.text(0, 1.02, text, transform=ax.transAxes, ha="left", va="bottom",
            fontsize=10.5, color=t["ink_2"])


def _money(x, _pos=None) -> str:
    return f"${x / 1000:.0f}K" if abs(x) >= 1000 else f"${x:.0f}"


def _usd(x: float) -> str:
    return f"${x:,.0f}"


def _source(fig, t: dict) -> None:
    """Source line just under the lowest drawn element, so it never overlaps axis labels."""
    renderer = fig.canvas.get_renderer()
    bottom = min(a.get_tightbbox(renderer).transformed(fig.transFigure.inverted()).y0
                 for a in fig.axes)
    fig.text(0.01, bottom - 0.015, "Source: Pizza Place Sales, 2015 (Maven Analytics Data "
             "Playground). Numbers from results/*.csv.", fontsize=10, color=t["muted"],
             ha="left", va="top")


# 1. Menu Pareto -------------------------------------------------------------------------
def menu_pareto(results: Path, out: Path, mode: str) -> Path:
    t = TOKENS[mode]
    rows = _read(results, "10_menu_pareto")
    cut = {r["pizza_name"] for r in _read(results, "11_menu_cut_candidates")
           if r["recommendation"] == "cut candidate"}
    names = [r["pizza_name"].removeprefix("The ").removesuffix(" Pizza") for r in rows]
    revenue = [float(r["revenue"]) for r in rows]
    top = [r["in_top_80pct"] == "true" for r in rows]
    n_top = sum(top)

    fig, ax = plt.subplots(figsize=(7.2, 9.6))
    y = list(range(len(rows)))
    ax.barh(y, revenue, height=0.62, color=[t["accent"] if f else t["context"] for f in top])
    ax.invert_yaxis()
    ax.set_yticks(y, names)
    ax.xaxis.set_major_formatter(FuncFormatter(_money))
    ax.grid(axis="y", visible=False)
    ax.set_xlim(0, max(revenue) * 1.22)
    ax.axhline(n_top - 0.5, color=t["ink_2"], linewidth=0.8)
    ax.text(max(revenue) * 1.2, n_top - 0.75, f"80% of revenue reached at pizza {n_top}",
            ha="right", va="bottom", fontsize=10.5, color=t["ink_2"])
    for i, r in enumerate(rows):
        if i == 0 or r["pizza_name"] in cut:
            label = _usd(revenue[i]) + ("   cut candidate" if r["pizza_name"] in cut else "")
            ax.text(revenue[i] + max(revenue) * 0.01, i, label, va="center",
                    fontsize=10.5, color=t["ink_2"])
    ax.set_title(f"Revenue is spread wide: {n_top} of {len(rows)} pizzas make up 80% of it")
    _subtitle(ax, "2015 revenue by pizza, highest first. Cut candidates sit in the bottom "
                  "quarter on revenue and units.", t)
    ax.legend(handles=[Patch(color=t["accent"], label="pizzas inside the first 80%"),
                       Patch(color=t["context"], label="the last 20% of revenue")],
              loc="lower right", bbox_to_anchor=(1.0, 0.0))
    _source(fig, t)
    return _save(fig, out, "menu_pareto", mode)


# 2. Staffing heatmap --------------------------------------------------------------------
def staffing_heatmap(results: Path, out: Path, mode: str) -> Path:
    t = TOKENS[mode]
    rows = _read(results, "20_staffing_hour_weekday")
    days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    hours = list(range(11, 24))
    grid = [[0.0] * len(hours) for _ in days]
    for r in rows:
        h = int(r["hour"])
        if h in hours:
            grid[days.index(r["weekday"])][hours.index(h)] = float(r["avg_orders_per_day"])

    cmap = LinearSegmentedColormap.from_list("heat", t["heat"])
    fig, ax = plt.subplots(figsize=(7.4, 4.6))
    mesh = ax.pcolormesh(grid, cmap=cmap, edgecolors=t["surface"], linewidth=2, vmin=0)
    ax.invert_yaxis()
    ax.set_xticks([i + 0.5 for i in range(len(hours))], [str(h) for h in hours])
    ax.set_yticks([i + 0.5 for i in range(len(days))], days)
    ax.set_xlabel("hour the order arrived (24-hour clock)")
    ax.grid(False)
    ax.spines["bottom"].set_visible(False)
    peak = max(max(row) for row in grid)
    for i, row in enumerate(grid):
        for j, v in enumerate(row):
            if v >= 0.92 * peak:   # label only the peak cells
                ax.text(j + 0.5, i + 0.5, f"{v:.1f}", ha="center", va="center", fontsize=10.5,
                        color="#FFFFFF" if mode == "light" else "#221E1C", fontweight="semibold")
    cbar = fig.colorbar(mesh, ax=ax, fraction=0.03, pad=0.02)
    cbar.outline.set_visible(False)
    cbar.ax.tick_params(colors=t["ink_2"], labelsize=10.5)
    cbar.set_label("orders per hour, average open day", color=t["ink_2"], fontsize=10.5)
    ax.set_title("Two daily peaks: lunch from 12:00 and dinner from 17:00")
    _subtitle(ax, "Average orders arriving in each hour, by weekday. Labelled cells are the "
                  "busiest hours of the week.", t)
    _source(fig, t)
    return _save(fig, out, "staffing_heatmap", mode)


# 3. Daily trend -------------------------------------------------------------------------
def daily_trend(results: Path, out: Path, mode: str) -> Path:
    import datetime as dt

    t = TOKENS[mode]
    rows = _read(results, "41_daily_rolling_7d")
    dates = [dt.date.fromisoformat(r["order_date"]) for r in rows]
    daily = [float(r["revenue"]) if r["open"] == "true" else float("nan") for r in rows]
    rolling = [float(r["rolling_7d_avg_revenue"]) for r in rows]

    fig, ax = plt.subplots(figsize=(7.4, 4.6))
    ax.plot(dates, daily, color=t["context"], linewidth=1, label="daily revenue (open days)")
    ax.plot(dates, rolling, color=t["accent"], linewidth=2, label="7-day average")
    ax.yaxis.set_major_formatter(FuncFormatter(_money))
    ax.set_ylim(0, max(d for d in daily if d == d) * 1.15)
    ax.grid(axis="x", visible=False)
    ax.spines["bottom"].set_color(t["axis"])
    import matplotlib.dates as mdates

    ax.xaxis.set_major_locator(mdates.MonthLocator())
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%b"))
    best = max(range(len(rows)), key=lambda i: daily[i] if daily[i] == daily[i] else -1)
    ax.annotate(f"busiest day, {dates[best]:%d %b}: {_usd(daily[best])}",
                xy=(dates[best], daily[best]), xytext=(-4, 4), textcoords="offset points",
                ha="right", va="bottom", fontsize=10.5, color=t["ink_2"])
    ax.text(dates[-1], rolling[-1], f"  {_usd(rolling[-1])}", va="center",
            fontsize=10.5, color=t["ink_2"])
    ax.legend(loc="lower left", ncols=2)
    avg = sum(d for d in daily if d == d) / sum(1 for d in daily if d == d)
    ax.set_title(f"No growth trend: daily revenue stays near {_usd(avg)} all year")
    _subtitle(ax, "Revenue per day in 2015. The 7-day average counts the 7 closed days "
                  "as zero, so closures show as dips.", t)
    _source(fig, t)
    return _save(fig, out, "daily_trend", mode)


# 4. Size mix ----------------------------------------------------------------------------
def size_mix(results: Path, out: Path, mode: str) -> Path:
    t = TOKENS[mode]
    rows = _read(results, "30_size_mix")
    sizes = [r["size"] for r in rows]
    share = [float(r["revenue_share_pct"]) for r in rows]

    fig, ax = plt.subplots(figsize=(7.4, 3.9))
    y = list(range(len(rows)))
    ax.barh(y, share, height=0.6, color=t["ordinal"][: len(rows)])
    ax.invert_yaxis()
    ax.set_yticks(y, sizes)
    ax.grid(axis="y", visible=False)
    ax.set_xlim(0, max(share) * 1.35)
    ax.xaxis.set_major_formatter(FuncFormatter(lambda x, _p: f"{x:.0f}%"))
    for i, r in enumerate(rows):
        ax.text(share[i] + 0.6, i, f"{share[i]:.1f}%  ({int(r['pizzas_sold']):,} pizzas, "
                f"{r['pizza_types_on_menu']} on menu)", va="center", fontsize=10.5,
                color=t["ink_2"])
    xl = sum(s for s, z in zip(share, sizes) if z in ("XL", "XXL"))
    ax.set_title(f"Large earns the most; XL and XXL together earn {xl:.1f}%")
    _subtitle(ax, "Share of 2015 revenue by pizza size, smallest to largest.", t)
    _source(fig, t)
    return _save(fig, out, "size_mix", mode)


def _save(fig, out: Path, name: str, mode: str) -> Path:
    out.mkdir(parents=True, exist_ok=True)
    path = out / (f"{name}.png" if mode == "light" else f"{name}-{mode}.png")
    fig.savefig(path)
    plt.close(fig)
    return path


CHARTS = (menu_pareto, staffing_heatmap, daily_trend, size_mix)


def render_all(results: Path, out: Path) -> list[Path]:
    paths = []
    for mode in ("light", "dark"):
        with plt.style.context(STYLE), plt.rc_context(_theme(mode)):
            for chart in CHARTS:
                paths.append(chart(Path(results), Path(out), mode))
    return paths
