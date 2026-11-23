-- 41_daily_rolling_7d.sql
-- Question:  What is the underlying daily trend once day-to-day noise is smoothed out?
-- Why a manager cares: single days swing with the weekday; a 7-day average shows whether
--            the business is actually speeding up or slowing down.
-- Technique: a calendar from GENERATE_SERIES so closed days count as zero (a window over
--            open days only would silently stretch past 7 calendar days), then
--            AVG() OVER (ROWS BETWEEN 6 PRECEDING AND CURRENT ROW).

WITH calendar AS (
    SELECT CAST(d AS DATE) AS order_date
    FROM GENERATE_SERIES(CAST((SELECT MIN(order_date) FROM orders) AS TIMESTAMP),
                         CAST((SELECT MAX(order_date) FROM orders) AS TIMESTAMP),
                         INTERVAL 1 DAY) AS t(d)
),
daily AS (
    SELECT order_date, COUNT(DISTINCT order_id) AS orders, SUM(line_revenue) AS revenue
    FROM sales
    GROUP BY order_date
)
SELECT
    c.order_date,
    COALESCE(d.orders, 0)                        AS orders,
    ROUND(COALESCE(d.revenue, 0), 2)             AS revenue,
    d.order_date IS NOT NULL                     AS open,
    ROUND(AVG(COALESCE(d.revenue, 0)) OVER w, 2) AS rolling_7d_avg_revenue,
    ROUND(AVG(COALESCE(d.orders, 0))  OVER w, 2) AS rolling_7d_avg_orders
FROM calendar c
LEFT JOIN daily d ON d.order_date = c.order_date
WINDOW w AS (ORDER BY c.order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW)
ORDER BY c.order_date;
