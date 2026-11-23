# Findings and recommendations

All numbers come from `results/*.csv`, produced by `make all` on the real dataset
(21,350 orders, 48,620 order lines, 1 Jan to 31 Dec 2015, 358 open days). Each finding names
the file it comes from. All 10 data-quality checks pass (`results/02_data_quality.csv`).

**Baseline** (`03_headline_kpis.csv`): $817,860 revenue, 49,574 pizzas, $38.31 average order,
2.32 pizzas per order, 59.6 orders and $2,285 revenue per open day.

## 1. The menu is not 80/20, so cut carefully

- 22 of the 32 pizzas are needed to reach 80% of revenue (`10_menu_pareto.csv`). The best
  seller (Thai Chicken, $43,434) earns only 5.3% of revenue. Demand is spread wide.
- 7 pizzas sit in the bottom quarter on both revenue and units sold
  (`11_menu_cut_candidates.csv`): Brie Carre, Spinach Supreme, Mediterranean, Spinach Pesto,
  Calabrese, Italian Vegetables, Soppressata. Together they earn $106,202 (13.0% of revenue)
  from 6,223 pizzas.
- Brie Carre is the clear outlier: 490 sold, about half of the next lowest (Mediterranean, 934).

**Recommendation:** remove Brie Carre now. Do not cut all seven at once: 13% of revenue is at
stake and the data cannot show whether those customers would switch to another pizza. Remove
them one at a time and watch weekly revenue (`40_weekly_growth.csv`) for two to four weeks each.

## 2. Staff for two peaks, and for Friday nights

- Lunch is the sharpest peak: 8.1 to 8.4 orders per hour from 12:00 to 13:59 on weekdays
  (`20_staffing_hour_weekday.csv`). Dinner (17:00 to 19:59) is a second, flatter peak.
- Friday is the busiest day at 70.8 orders, 40% more than Sunday (50.5). After 20:00, Friday
  takes 15.6 orders per evening against 8.0 on Sunday.
- Almost nothing happens before 11:00 (9 orders all year) or after 23:00.

**Recommendation:** put the most staff on 11:30 to 14:00 Monday to Friday, keep a second full
shift for 17:00 to 20:00, extend the Friday and Saturday evening shift to closing, and run
Sunday lighter.

## 3. XL and XXL do not earn their place

- Only one pizza (The Greek) comes in XL and XXL. Together these two sizes earn 1.8% of
  revenue: XL 552 pizzas ($14,076), XXL 28 pizzas all year ($1,007) (`30_size_mix.csv`).
- Large is the workhorse: 38% of pizzas sold and 46% of revenue.

**Recommendation:** drop XXL (about one sale every 13 days) and the box stock that comes with
it. Keep XL only if its boxes are shared with another product.

## 4. Sales are flat all year: growth has to be created

- Revenue per open day was $2,286 in January to June and $2,283 in July to December
  (`41_daily_rolling_7d.csv`). Between full weeks the median week-over-week change is 4.5%,
  and the biggest drop (-15.9%) is the week of 30 November, right after the Thanksgiving peak
  (`40_weekly_growth.csv`).
- Monthly revenue per open day stays within 94 to 104 of the yearly average
  (`60_seasonality_monthly.csv`). December is weakest (index 94.4), October strongest (103.8).
- The 7 days with no orders (24 and 25 September, the four Mondays from 5 to 26 October, and
  25 December) explain most of the dips in the 7-day average.

**Recommendation:** treat the year as a stable baseline. Bigger baskets and a leaner menu are
where revenue can move, not seasonal timing.

## 5. Bigger baskets matter more than combo pairs

- One-pizza orders are 38% of all orders but only 16% of revenue (`70_aov_drivers.csv`).
  Orders of 4 pizzas bring in 25% of revenue from 15% of orders.
- No two pizzas are bought together much more than chance: among the 25 most common pairs, lift
  runs from 0.97 to 1.22 (`50_market_basket.csv`). The most common pair (Hawaiian with Thai
  Chicken) shares 270 orders, 1.3% of all orders.
- Lunch orders are the largest by value ($42.36 on average, 2.56 pizzas) against $35.17 late
  in the evening.

**Recommendation:** a "second pizza" offer on single-pizza orders targets the biggest gap. A
named combo of two specific pizzas has little support in the data.

## Also in the results

- `80_ingredient_demand.csv`: garlic (27,913 pizzas) and tomatoes (27,052) go into the most
  pizzas sold. 38 of the 65 ingredients appear in only one pizza, which matters for stock and
  waste if that pizza is cut.

## Limits

- One shop, one year (2015), fictional data. There is no customer id, so repeat visits and
  customer cohorts cannot be measured, and there is no cost data, so revenue is not profit.
- Cutting a pizza assumes some of its customers buy something else; this data cannot test
  that. Treat each cut as an experiment.
