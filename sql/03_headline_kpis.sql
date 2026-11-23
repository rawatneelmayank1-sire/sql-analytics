-- 03_headline_kpis.sql
-- Question:  How big is the business in one line: orders, pizzas, revenue, ticket size?
-- Why a manager cares: these are the baseline every other decision is measured against
--            (a 5% lift in average order value means nothing without knowing the base).
-- Technique: a CTE at order grain first, so order-level averages are not distorted by
--            line-level rows; COUNT(DISTINCT) for open days; ROUND on DECIMAL sums.

WITH order_totals AS (
    SELECT order_id, order_date,
           SUM(quantity)     AS pizzas,
           SUM(line_revenue) AS order_value
    FROM sales
    GROUP BY order_id, order_date
)
SELECT
    COUNT(*)                                                AS total_orders,
    SUM(pizzas)                                             AS total_pizzas,
    ROUND(SUM(order_value), 2)                              AS total_revenue,
    ROUND(AVG(order_value), 2)                              AS avg_order_value,
    ROUND(AVG(pizzas), 2)                                   AS avg_pizzas_per_order,
    COUNT(DISTINCT order_date)                              AS days_open,
    ROUND(COUNT(*) / COUNT(DISTINCT order_date), 1)         AS avg_orders_per_day,
    ROUND(SUM(order_value) / COUNT(DISTINCT order_date), 2) AS avg_revenue_per_day,
    MIN(order_date)                                         AS first_day,
    MAX(order_date)                                         AS last_day
FROM order_totals;
