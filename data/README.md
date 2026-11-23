# Data

| File | Rows | Columns |
|---|---:|---|
| `raw/orders.csv` | 21,350 | order_id, date, time |
| `raw/order_details.csv` | 48,620 | order_details_id, order_id, pizza_id, quantity |
| `raw/pizzas.csv` | 96 | pizza_id, pizza_type_id, size, price |
| `raw/pizza_types.csv` | 32 | pizza_type_id, name, category, ingredients |

**Source:** "Pizza Place Sales", Maven Analytics Data Playground,
<https://mavenanalytics.io/data-playground/pizza-place-sales>. One year (2015) of orders
from a fictional pizza restaurant. The page lists the licence as **Public Domain** and the
original source as Rdatasets (Vincent Arel-Bundock).

The CSVs are not committed (`.gitignore`). `make all` or `python scripts/download_data.py`
fetches them from Maven's official download link (1.9 MB unzipped). The original
`pizza_types.csv` is Windows-1252 encoded; the script stores it as UTF-8 (one character
changes encoding, the curly quote in "'Nduja").
