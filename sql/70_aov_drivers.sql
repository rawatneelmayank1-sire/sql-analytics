-- 70_aov_drivers.sql
-- Question:  What drives the size of an order: how many pizzas, and what time of day?
-- Why a manager cares: average order value (AOV) moves with basket size. If one-pizza
--            orders are most orders but a smaller share of revenue, an "add a second pizza"
--            offer is where AOV can grow.
-- Technique: an order-level CTE, then GROUPING SETS to report two drivers (basket size and
--            day part) in one result, with shares from SUM() OVER (PARTITION BY driver).

WITH order_totals AS (
    SELECT order_id,
           MIN(order_time)   AS order_time,
           SUM(quantity)     AS pizzas,
           SUM(line_revenue) AS order_value
    FROM sales
    GROUP BY order_id
),
labelled AS (
    SELECT *,
           CASE WHEN pizzas >= 5 THEN '5 or more' ELSE CAST(pizzas AS VARCHAR) END AS basket_size,
           CASE WHEN HOUR(order_time) < 11 THEN '1 before 11:00'
                WHEN HOUR(order_time) < 14 THEN '2 lunch 11:00 to 13:59'
                WHEN HOUR(order_time) < 17 THEN '3 afternoon 14:00 to 16:59'
                WHEN HOUR(order_time) < 20 THEN '4 dinner 17:00 to 19:59'
                ELSE '5 late 20:00 and after' END                                AS day_part
    FROM order_totals
),
grouped AS (
    SELECT
        CASE WHEN GROUPING(basket_size) = 0 THEN 'pizzas in order' ELSE 'time of day' END AS driver,
        COALESCE(basket_size, day_part) AS segment,
        COUNT(*)                        AS orders,
        SUM(order_value)                AS revenue,
        AVG(order_value)                AS avg_order_value,
        AVG(pizzas)                     AS avg_pizzas
    FROM labelled
    GROUP BY GROUPING SETS ((basket_size), (day_part))
)
SELECT
    driver,
    segment,
    orders,
    ROUND(100.0 * orders  / SUM(orders)  OVER (PARTITION BY driver), 2) AS order_share_pct,
    ROUND(revenue, 2)                                                   AS revenue,
    ROUND(100.0 * revenue / SUM(revenue) OVER (PARTITION BY driver), 2) AS revenue_share_pct,
    ROUND(avg_order_value, 2)                                           AS avg_order_value,
    ROUND(avg_pizzas, 2)                                                AS avg_pizzas
FROM grouped
ORDER BY driver, segment;
