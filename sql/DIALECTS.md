# Running the SQL on MySQL or PostgreSQL

The queries are written for DuckDB, which runs in-process with no server. Almost all of the
SQL is standard (CTEs, window functions, GROUPING SETS). These are the parts to change:

| DuckDB (this repo) | MySQL 8 | PostgreSQL 14+ |
|---|---|---|
| `read_csv('file.csv', header = true)` | `LOAD DATA LOCAL INFILE ... IGNORE 1 LINES` | `\copy table FROM 'file.csv' WITH (FORMAT csv, HEADER true)` |
| `ISODOW(d)` | `WEEKDAY(d) + 1` | `EXTRACT(ISODOW FROM d)` |
| `HOUR(t)` | `HOUR(t)` | `EXTRACT(HOUR FROM t)` |
| `DATE_TRUNC('week', d)` | `DATE_SUB(d, INTERVAL WEEKDAY(d) DAY)` | `DATE_TRUNC('week', d)::date` |
| `DATE_TRUNC('month', d)` | `DATE_FORMAT(d, '%Y-%m-01')` | `DATE_TRUNC('month', d)::date` |
| `STRFTIME(d, '%b')` | `DATE_FORMAT(d, '%b')` | `TO_CHAR(d, 'Mon')` |
| `GENERATE_SERIES(a, b, INTERVAL 1 DAY)` | recursive CTE over dates | `GENERATE_SERIES(a, b, INTERVAL '1 day')` |
| `UNNEST(STRING_SPLIT(s, ','))` | `JSON_TABLE` or a numbers table | `UNNEST(STRING_TO_ARRAY(s, ','))` |
| `WINDOW w AS (...)` | supported | supported |
| `GROUPING SETS ((a), (b))` | not supported: use `UNION ALL` of two GROUP BYs | supported |
| `x / y` on integers gives a decimal | same | integer division: cast one side to `numeric` |

The schema (`00_schema.sql`) runs unchanged on PostgreSQL. On MySQL, `VARCHAR` lengths are
already set and `CHECK` constraints are enforced from 8.0.16.
