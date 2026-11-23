-- 30_size_mix.sql
-- Question:  What does each size contribute, and do XL and XXL earn their place?
-- Why a manager cares: every size needs its own boxes, dough weights and prep steps.
--            A size with a tiny share of revenue is a candidate to drop or fold into L.
-- Technique: GROUP BY with share of total via SUM() OVER (), an ordinal sort with CASE,
--            and a second CTE for what the menu offers in each size.

WITH by_size AS (
    SELECT size,
           SUM(quantity)     AS pizzas_sold,
           SUM(line_revenue) AS revenue
    FROM sales
    GROUP BY size
),
offered AS (
    SELECT size, COUNT(*) AS pizza_types_on_menu, ROUND(AVG(price), 2) AS avg_menu_price
    FROM pizzas
    GROUP BY size
)
SELECT
    b.size,
    o.pizza_types_on_menu,
    b.pizzas_sold,
    ROUND(b.revenue, 2)                                          AS revenue,
    ROUND(100.0 * b.pizzas_sold / SUM(b.pizzas_sold) OVER (), 2) AS volume_share_pct,
    ROUND(100.0 * b.revenue / SUM(b.revenue) OVER (), 2)         AS revenue_share_pct,
    ROUND(b.revenue / b.pizzas_sold, 2)                          AS avg_price_paid,
    o.avg_menu_price
FROM by_size b
JOIN offered o USING (size)
ORDER BY CASE b.size WHEN 'S' THEN 1 WHEN 'M' THEN 2 WHEN 'L' THEN 3 WHEN 'XL' THEN 4 ELSE 5 END;
