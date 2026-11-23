-- 20_staffing_hour_weekday.sql
-- Question:  On a typical day of each weekday, how many orders arrive in each hour?
-- Why a manager cares: rota planning. Staff should follow the demand curve, so the useful
--            number is the average per open day, not the yearly total per hour.
-- Technique: date parts (ISODOW, HOUR), a CTE counting how many of each weekday the shop
--            was open, and a join that turns totals into per-day averages (a heatmap grid).

WITH days_open AS (
    SELECT ISODOW(order_date) AS weekday_num, COUNT(DISTINCT order_date) AS open_days
    FROM orders
    GROUP BY 1
),
by_slot AS (
    SELECT ISODOW(o.order_date)       AS weekday_num,
           HOUR(o.order_time)         AS hour,
           COUNT(DISTINCT o.order_id) AS orders,
           SUM(od.quantity)           AS pizzas
    FROM orders o
    JOIN order_details od ON od.order_id = o.order_id
    GROUP BY 1, 2
)
SELECT
    s.weekday_num,
    CASE s.weekday_num WHEN 1 THEN 'Mon' WHEN 2 THEN 'Tue' WHEN 3 THEN 'Wed' WHEN 4 THEN 'Thu'
                       WHEN 5 THEN 'Fri' WHEN 6 THEN 'Sat' ELSE 'Sun' END AS weekday,
    s.hour,
    s.orders,
    s.pizzas,
    d.open_days,
    ROUND(s.orders / d.open_days, 2) AS avg_orders_per_day,
    ROUND(s.pizzas / d.open_days, 2) AS avg_pizzas_per_day
FROM by_slot s
JOIN days_open d USING (weekday_num)
ORDER BY s.weekday_num, s.hour;
