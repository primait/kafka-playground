.PHONY: install
install: ## Install dependencies
	poetry run pip install --upgrade pip
	poetry install -v


.PHONY: python-models
python-models: ## Generate python models starting from avro schemas
	poetry run generate_models ../schemas ./python_aiokafka/models


.PHONY: format
format: ## Format repository code
	poetry run black .
	poetry run isort .