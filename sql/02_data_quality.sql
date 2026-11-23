-- 02_data_quality.sql
-- Question:  Did the load work, and can the numbers below be trusted?
-- Why a manager cares: every later figure is only as good as the rows under it. Orphan
--            lines, duplicate menu items or a pizza priced below its smaller size would
--            quietly skew revenue.
-- Technique: one UNION ALL of named checks, each returning a count that should be zero
--            (or a row count to compare with the CSV), with a pass/fail flag. LAG() over
--            size order checks that price rises with size.

WITH checks AS (
    SELECT 1 AS check_id, 'orders loaded' AS check_name, COUNT(*) AS value, COUNT(*) > 0 AS passed
    FROM orders
    UNION ALL
    SELECT 2, 'order lines loaded', COUNT(*), COUNT(*) > 0 FROM order_details
    UNION ALL
    SELECT 3, 'menu items (pizza and size) loaded', COUNT(*), COUNT(*) > 0 FROM pizzas
    UNION ALL
    SELECT 4, 'pizza types loaded', COUNT(*), COUNT(*) > 0 FROM pizza_types
    UNION ALL
    SELECT 5, 'order lines with no matching order', COUNT(*), COUNT(*) = 0
    FROM order_details od LEFT JOIN orders o ON o.order_id = od.order_id
    WHERE o.order_id IS NULL
    UNION ALL
    SELECT 6, 'order lines with no matching menu item', COUNT(*), COUNT(*) = 0
    FROM order_details od LEFT JOIN pizzas p ON p.pizza_id = od.pizza_id
    WHERE p.pizza_id IS NULL
    UNION ALL
    SELECT 7, 'orders with no order lines', COUNT(*), COUNT(*) = 0
    FROM orders o LEFT JOIN order_details od ON od.order_id = o.order_id
    WHERE od.order_id IS NULL
    UNION ALL
    SELECT 8, 'menu items sharing a pizza type and size', COUNT(*), COUNT(*) = 0
    FROM (SELECT pizza_type_id, size FROM pizzas GROUP BY 1, 2 HAVING COUNT(*) > 1) AS dup
    UNION ALL
    SELECT 9, 'bigger sizes priced below the next smaller size', COUNT(*), COUNT(*) = 0
    FROM (
        SELECT price,
               LAG(price) OVER (PARTITION BY pizza_type_id
                                ORDER BY CASE size WHEN 'S' THEN 1 WHEN 'M' THEN 2 WHEN 'L' THEN 3
                                                   WHEN 'XL' THEN 4 ELSE 5 END) AS smaller_price
        FROM pizzas
    ) AS steps
    WHERE price < smaller_price
    UNION ALL
    SELECT 10, 'order lines with quantity above 4 (outliers to review)', COUNT(*), TRUE
    FROM order_details WHERE quantity > 4
)
SELECT check_id, check_name, value, passed
FROM checks
ORDER BY check_id;
