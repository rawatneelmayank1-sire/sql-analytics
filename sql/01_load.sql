-- 01_load.sql
-- Loads the four raw CSVs into the schema from 00_schema.sql (DuckDB).
-- {{DATA_DIR}} is replaced by the runner (src/sql_analytics/run.py) with the CSV folder.
-- Parent tables load first so every foreign key is satisfied.
-- All four files are UTF-8 (scripts/download_data.py converts the Windows-1252 original).
--
-- MySQL:      LOAD DATA LOCAL INFILE '.../orders.csv' INTO TABLE orders
--             FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' IGNORE 1 LINES;
-- PostgreSQL: \copy orders FROM '.../orders.csv' WITH (FORMAT csv, HEADER true);

INSERT INTO pizza_types
SELECT pizza_type_id, name, category, ingredients
FROM read_csv('{{DATA_DIR}}/pizza_types.csv', header = true,
              columns = {'pizza_type_id': 'VARCHAR', 'name': 'VARCHAR',
                         'category': 'VARCHAR', 'ingredients': 'VARCHAR'});

INSERT INTO pizzas
SELECT pizza_id, pizza_type_id, size, CAST(price AS DECIMAL(6, 2))
FROM read_csv('{{DATA_DIR}}/pizzas.csv', header = true,
              columns = {'pizza_id': 'VARCHAR', 'pizza_type_id': 'VARCHAR',
                         'size': 'VARCHAR', 'price': 'DOUBLE'});

INSERT INTO orders
SELECT order_id, "date", "time"
FROM read_csv('{{DATA_DIR}}/orders.csv', header = true,
              columns = {'order_id': 'INTEGER', 'date': 'DATE', 'time': 'TIME'});

INSERT INTO order_details
SELECT order_details_id, order_id, pizza_id, quantity
FROM read_csv('{{DATA_DIR}}/order_details.csv', header = true,
              columns = {'order_details_id': 'INTEGER', 'order_id': 'INTEGER',
                         'pizza_id': 'VARCHAR', 'quantity': 'INTEGER'});
