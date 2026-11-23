-- 11_menu_cut_candidates.sql
-- Question:  Which pizzas are weak on BOTH revenue and volume, and so are safe to cut?
-- Why a manager cares: a pizza that sells few units at a high price still earns its place;
--            one that is low on both is the clean cut. Cutting on one measure alone can
--            remove the wrong items.
-- Technique: NTILE(4) quartiles over two different orderings in one pass, a CASE label,
--            and the full menu kept in the result for context.

WITH per_pizza AS (
    SELECT pizza_name, category,
           SUM(quantity)            AS pizzas_sold,
           SUM(line_revenue)        AS revenue,
           COUNT(DISTINCT order_id) AS orders_containing
    FROM sales
    GROUP BY pizza_name, category
),
quartiles AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY revenue, pizza_name)     AS revenue_quartile,  -- 1 = bottom 25%
           NTILE(4) OVER (ORDER BY pizzas_sold, pizza_name) AS volume_quartile
    FROM per_pizza
)
SELECT
    pizza_name,
    category,
    pizzas_sold,
    ROUND(revenue, 2)               AS revenue,
    ROUND(revenue / pizzas_sold, 2) AS avg_price_paid,
    orders_containing,
    revenue_quartile,
    volume_quartile,
    CASE
        WHEN revenue_quartile = 1 AND volume_quartile = 1 THEN 'cut candidate'
        WHEN revenue_quartile = 1 OR  volume_quartile = 1 THEN 'watch'
        ELSE 'keep'
    END                             AS recommendation
FROM quartiles
ORDER BY revenue ASC, pizza_name;
