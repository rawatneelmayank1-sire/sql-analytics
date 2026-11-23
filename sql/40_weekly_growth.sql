-- 40_weekly_growth.sql
-- Question:  Week by week, is revenue growing, flat or falling?
-- Why a manager cares: week-over-week change catches a bad week (a failed promotion, a
--            closure) within days instead of at month end.
-- Technique: DATE_TRUNC('week') buckets (weeks start Monday), LAG() for the previous
--            week, and a days-open count so partial weeks at the ends of the year are
--            flagged instead of compared as if they were full weeks.

WITH weekly AS (
    SELECT CAST(DATE_TRUNC('week', order_date) AS DATE) AS week_start,
           COUNT(DISTINCT order_date)                   AS days_open,
           COUNT(DISTINCT order_id)                     AS orders,
           SUM(line_revenue)                            AS revenue
    FROM sales
    GROUP BY 1
),
with_prev AS (
    SELECT *,
           LAG(revenue)   OVER (ORDER BY week_start) AS prev_revenue,
           LAG(days_open) OVER (ORDER BY week_start) AS prev_days_open
    FROM weekly
)
SELECT
    week_start,
    days_open,
    orders,
    ROUND(revenue, 2)                                         AS revenue,
    ROUND(prev_revenue, 2)                                    AS prev_week_revenue,
    -- only compare like with like: both weeks must have been open all 7 days
    CASE WHEN days_open = 7 AND prev_days_open = 7
         THEN ROUND(100.0 * (revenue - prev_revenue) / prev_revenue, 2)
    END                                                       AS wow_change_pct,
    days_open = 7                                             AS full_week
FROM with_prev
ORDER BY week_start;
