-- 10_menu_pareto.sql
-- Question:  How concentrated is revenue? How many of the pizzas earn 80% of it?
-- Why a manager cares: if a small share of the menu earns most of the money, the long tail
--            costs prep time, stock and menu space for little return (the 80/20 check).
-- Technique: aggregate per pizza type, then window functions: RANK() for position and
--            SUM() OVER (ORDER BY ... ROWS UNBOUNDED PRECEDING) for the running share.

WITH revenue_by_pizza AS (
    SELECT pizza_name, category,
           SUM(quantity)     AS pizzas_sold,
           SUM(line_revenue) AS revenue
    FROM sales
    GROUP BY pizza_name, category
),
ranked AS (
    SELECT *,
           RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
           SUM(revenue) OVER (ORDER BY revenue DESC, pizza_name
                              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_revenue,
           SUM(revenue) OVER () AS total_revenue,
           COUNT(*)     OVER () AS menu_size
    FROM revenue_by_pizza
)
SELECT
    revenue_rank,
    pizza_name,
    category,
    pizzas_sold,
    ROUND(revenue, 2)                                 AS revenue,
    ROUND(100.0 * revenue / total_revenue, 2)         AS revenue_share_pct,
    ROUND(100.0 * running_revenue / total_revenue, 2) AS cumulative_share_pct,
    -- in the "vital few" if the running share before this pizza was still under 80%
    (running_revenue - revenue) < 0.8 * total_revenue AS in_top_80pct
FROM ranked
ORDER BY revenue_rank, pizza_name;
