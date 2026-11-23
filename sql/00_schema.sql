-- 00_schema.sql
-- Normalised schema for one year of pizza restaurant orders.
--
--   pizza_types (1) ──< pizzas (1) ──< order_details >── (1) orders
--
-- Prices are DECIMAL(6,2), not FLOAT, so revenue sums are exact to the cent.
-- Written for DuckDB. MySQL / PostgreSQL notes are in sql/DIALECTS.md.

DROP VIEW  IF EXISTS sales;
DROP TABLE IF EXISTS order_details;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS pizzas;
DROP TABLE IF EXISTS pizza_types;

CREATE TABLE pizza_types (
    pizza_type_id VARCHAR(20)  PRIMARY KEY,
    name          VARCHAR(80)  NOT NULL,
    category      VARCHAR(20)  NOT NULL,
    ingredients   VARCHAR(300) NOT NULL
);

CREATE TABLE pizzas (
    pizza_id      VARCHAR(25)   PRIMARY KEY,
    pizza_type_id VARCHAR(20)   NOT NULL REFERENCES pizza_types (pizza_type_id),
    size          VARCHAR(3)    NOT NULL CHECK (size IN ('S', 'M', 'L', 'XL', 'XXL')),
    price         DECIMAL(6, 2) NOT NULL CHECK (price > 0)
);

CREATE TABLE orders (
    order_id   INTEGER PRIMARY KEY,
    order_date DATE    NOT NULL,
    order_time TIME    NOT NULL
);

CREATE TABLE order_details (
    order_details_id INTEGER     PRIMARY KEY,
    order_id         INTEGER     NOT NULL REFERENCES orders (order_id),
    pizza_id         VARCHAR(25) NOT NULL REFERENCES pizzas (pizza_id),
    quantity         INTEGER     NOT NULL CHECK (quantity > 0)
);

-- Join paths used by almost every analysis.
CREATE INDEX idx_order_details_order ON order_details (order_id);
CREATE INDEX idx_order_details_pizza ON order_details (pizza_id);
CREATE INDEX idx_pizzas_type         ON pizzas (pizza_type_id);
CREATE INDEX idx_orders_date         ON orders (order_date);

-- One row per order line with everything an analysis usually needs.
CREATE VIEW sales AS
SELECT
    od.order_details_id,
    o.order_id,
    o.order_date,
    o.order_time,
    p.pizza_id,
    p.size,
    p.price,
    pt.pizza_type_id,
    pt.name                 AS pizza_name,
    pt.category,
    od.quantity,
    od.quantity * p.price   AS line_revenue
FROM order_details AS od
JOIN orders        AS o  ON o.order_id = od.order_id
JOIN pizzas        AS p  ON p.pizza_id = od.pizza_id
JOIN pizza_types   AS pt ON pt.pizza_type_id = p.pizza_type_id;
