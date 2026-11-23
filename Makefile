PYTHON ?= python
export PYTHONPATH := src

.PHONY: all install data run test clean

all: data run test   ## download data if missing, run every query, draw charts, test

install:             ## install runtime and test dependencies
	$(PYTHON) -m pip install -r requirements.txt

data:                ## fetch the four CSVs from Maven Analytics (skipped if present)
	$(PYTHON) scripts/download_data.py

run:                 ## build DuckDB in memory, write results/*.csv and reports/*.png
	$(PYTHON) -m sql_analytics.run

test:                ## run every query against the hand-made fixture
	$(PYTHON) -m pytest -q

clean:
	rm -rf results/*.csv reports/*.png .pytest_cache
