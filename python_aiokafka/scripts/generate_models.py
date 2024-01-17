import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

import black
from dataclasses_avroschema import ModelGenerator
from isort import Config
from isort import code as sort_code


@dataclass
class AvroSchema:
    relative_path: Path
    schema_definition: dict[str, Any]


def generate_model(schema_path: Path, destination_path: Path):
    avro_schemas = _read_schema_path(schema_path)
    _write_models(avro_schemas, destination_path)


def _read_schema_path(schema_path: Path) -> list[AvroSchema]:
    if not schema_path.exists() and not schema_path.is_dir():
        raise FileNotFoundError(f"Schema directory not found: {schema_path.absolute()}")

    avro_schemas = []
    for path in schema_path.glob("**/*.avsc"):
        print(f"Reading schema: {path}")
        with open(path, "r") as fp:
            avro_schemas.append(
                AvroSchema(
                    relative_path=path.relative_to(schema_path),
                    schema_definition=json.load(fp),
                )
            )
    return avro_schemas


def _write_models(avro_schemas: list[AvroSchema], destination_path: Path):
    model_generator = ModelGenerator()

    for schema in avro_schemas:
        print(f"Generating model: {schema.relative_path}")
        python_code = model_generator.render(schema=schema.schema_definition)
        python_code = _format_code(python_code)

        python_module_path = destination_path / schema.relative_path.with_suffix(".py")
        python_module_path.parent.mkdir(parents=True, exist_ok=True)
        with open(python_module_path, "w") as fp:
            fp.write(python_code)


def _format_code(code: str) -> str:
    pyproject_path = Path(__file__).parent.parent / "pyproject.toml"

    sorted_code = sort_code(code, config=Config(settings_path=pyproject_path))

    black_config = black.parse_pyproject_toml(pyproject_path)
    formatted_code = black.format_str(sorted_code, mode=black.FileMode(**black_config))

    return formatted_code


def main():
    parser = argparse.ArgumentParser(description="Generate model from Avro schema.")
    parser.add_argument("schema_path", type=Path, help="Path to the Avro schema file")
    parser.add_argument(
        "destination_path", type=Path, help="Path to save the generated model file"
    )
    args = parser.parse_args()

    generate_model(args.schema_path, args.destination_path)


if __name__ == "__main__":
    main()
