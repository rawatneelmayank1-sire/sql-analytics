-- 60_seasonality_monthly.sql
-- Question:  Which months are strong or weak once the number of open days is accounted for?
-- Why a manager cares: monthly totals mislead (February is short, some months have
--            closures). Revenue per open day, indexed to the average month, shows when to
--            run promotions and when to plan time off.
-- Technique: DATE_TRUNC('month'), revenue per open day, an index against AVG() OVER () of
--            all months, and RANK() to name the best and worst.
-- Note: the data has no customer id, so customer cohorts (repeat rates) cannot be built.
--       Month-of-year seasonality is the cohort view this dataset supports.

WITH monthly AS (
    SELECT CAST(DATE_TRUNC('month', order_date) AS DATE) AS month,
           COUNT(DISTINCT order_date)                    AS days_open,
           COUNT(DISTINCT order_id)                      AS orders,
           SUM(quantity)                                 AS pizzas,
           SUM(line_revenue)                             AS revenue
    FROM sales
    GROUP BY 1
)
SELECT
    month,
    STRFTIME(month, '%b')                                    AS month_name,
    days_open,
    orders,
    pizzas,
    ROUND(revenue, 2)                                        AS revenue,
    ROUND(revenue / days_open, 2)                            AS revenue_per_open_day,
    ROUND(100.0 * (revenue / days_open)
          / AVG(revenue / days_open) OVER (), 1)             AS index_vs_avg,
    RANK() OVER (ORDER BY revenue / days_open DESC)          AS rank_per_day
FROM monthly
ORDER BY month;
