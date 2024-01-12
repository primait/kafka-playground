import argparse
import json
from pathlib import Path

from dataclasses_avroschema import ModelGenerator


def generate_model(schema_path: Path, destination_path: Path):
    with open(schema_path, "r") as f:
        schema = json.load(f)
        print(schema)

    model_generator = ModelGenerator()
    result = model_generator.render(schema=schema)

    with open(destination_path, "w") as f:
        f.write(result)


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
