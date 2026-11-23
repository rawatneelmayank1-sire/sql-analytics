# Test fixture (hand-made, not real data)

These four CSVs are a tiny hand-written sample with the same columns as the real dataset:
4 pizza types, 11 menu items, 12 orders, 19 order lines. The pizza names start with
"The Fixture" so a fixture row can never be mistaken for a real one.

They exist only so `pytest` and CI can run every query in under a second without the real
data. No finding in this repo comes from these files.
