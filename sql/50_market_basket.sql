-- 50_market_basket.sql
-- Question:  Which pairs of pizzas are bought together in the same order most often?
-- Why a manager cares: strong pairs are ready-made combo deals. A pair with lift above 1
--            is bought together more often than chance would predict, so a bundle there
--            is more likely to land.
-- Technique: a self-join of order lines on order_id with a < b so each pair counts once,
--            then support, confidence and lift from three CTEs (pair counts, item counts,
--            total orders).

WITH order_items AS (   -- one row per (order, pizza type); size and quantity ignored
    SELECT DISTINCT order_id, pizza_name FROM sales
),
total AS (
    SELECT COUNT(DISTINCT order_id) AS n_orders FROM order_items
),
item_counts AS (
    SELECT pizza_name, COUNT(*) AS item_orders FROM order_items GROUP BY pizza_name
),
pairs AS (
    SELECT a.pizza_name AS pizza_a, b.pizza_name AS pizza_b, COUNT(*) AS orders_together
    FROM order_items a
    JOIN order_items b ON a.order_id = b.order_id AND a.pizza_name < b.pizza_name
    GROUP BY 1, 2
)
SELECT
    p.pizza_a,
    p.pizza_b,
    p.orders_together,
    ROUND(100.0 * p.orders_together / t.n_orders, 3)     AS support_pct,
    ROUND(100.0 * p.orders_together / ia.item_orders, 2) AS confidence_a_to_b_pct,
    ROUND(100.0 * p.orders_together / ib.item_orders, 2) AS confidence_b_to_a_pct,
    ROUND(1.0 * p.orders_together * t.n_orders / (ia.item_orders * ib.item_orders), 3) AS lift
FROM pairs p
CROSS JOIN total t
JOIN item_counts ia ON ia.pizza_name = p.pizza_a
JOIN item_counts ib ON ib.pizza_name = p.pizza_b
ORDER BY p.orders_together DESC, lift DESC, p.pizza_a, p.pizza_b
LIMIT 25;
