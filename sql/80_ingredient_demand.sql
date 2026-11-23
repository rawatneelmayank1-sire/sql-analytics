-- 80_ingredient_demand.sql
-- Question:  Which ingredients go into the most pizzas sold, and which appear in only one?
-- Why a manager cares: stock planning and waste. A topping used by a single slow pizza is
--            stock that spoils; the top toppings need the most reliable supplier.
-- Technique: UNNEST(STRING_SPLIT()) turns the comma list into one row per ingredient
--            (first normal form), TRIM cleans it, then a join weights it by units sold.

WITH ingredient_rows AS (
    SELECT pizza_type_id, TRIM(UNNEST(STRING_SPLIT(ingredients, ','))) AS ingredient
    FROM pizza_types
),
units AS (
    SELECT pizza_type_id, SUM(quantity) AS pizzas_sold
    FROM sales
    GROUP BY pizza_type_id
)
SELECT
    i.ingredient,
    COUNT(DISTINCT i.pizza_type_id)     AS pizza_types_using,
    COALESCE(SUM(u.pizzas_sold), 0)     AS pizzas_sold_containing,
    COUNT(DISTINCT i.pizza_type_id) = 1 AS single_pizza_ingredient
FROM ingredient_rows i
LEFT JOIN units u ON u.pizza_type_id = i.pizza_type_id
GROUP BY i.ingredient
ORDER BY pizzas_sold_containing DESC, i.ingredient;
