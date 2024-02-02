defmodule ElixirAvro.Generator.CollectorTest do
  use ExUnit.Case

  alias ElixirAvro.Generator.Collector

  @nested_record_full_name "atp.players.Trainer"

  test "inline record" do
    assert %{
             "atp.players.PlayerRegistered" => erlavro_schema_parsed_root_condensed(),
             "atp.players.Trainer" => erlavro_schema_parsed_nested_record()
           } ==
             Collector.collect(erlavro_schema_parsed_root_record())
  end

  defp erlavro_schema_parsed_nested_record() do
    {:avro_record_type, "Trainer", "", "", [],
     [
       {:avro_record_field, "fullname", "", {:avro_primitive_type, "string", []}, :undefined,
        :ascending, []}
     ], @nested_record_full_name, []}
  end

  defp erlavro_schema_parsed_root_condensed() do
    erlavro_type_scheleton(@nested_record_full_name)
  end

  defp erlavro_schema_parsed_root_record() do
    erlavro_type_scheleton(erlavro_schema_parsed_nested_record())
  end

  defp erlavro_type_scheleton(nested_record_type) do
    {:avro_record_type, "PlayerRegistered", "atp.players",
     "A new player is registered in the atp ranking system.", [],
     [
       {:avro_record_field, "player_id", "The unique identifier of the registered player (UUID).",
        {:avro_primitive_type, "string", [{"logicalType", "uuid"}]}, :undefined, :ascending, []},
       {:avro_record_field, "full_name", "The full name of the registered player.",
        {:avro_primitive_type, "string", []}, :undefined, :ascending, []},
       {:avro_record_field, "rank",
        "The current ranking of the registered player, start counting from 1.",
        {:avro_primitive_type, "int", []}, :undefined, :ascending, []},
       {:avro_record_field, "registration_date",
        "The date when the player was registered (number of UTC days from the unix epoch).",
        {:avro_primitive_type, "int", [{"logicalType", "date"}]}, :undefined, :ascending, []},
       {:avro_record_field, "sponsor_name", "The name of the current sponsor (optional).",
        {:avro_union_type,
         {2,
          {1, {:avro_primitive_type, "string", []},
           {0, {:avro_primitive_type, "null", []}, nil, nil}, nil}},
         {2, {"string", {1, true}, {"null", {0, true}, nil, nil}, nil}}}, :undefined, :ascending,
        []},
       {:avro_record_field, "trainer", "Current trainer.", nested_record_type,
        :undefined, :ascending, []}
     ], "atp.players.PlayerRegistered", []}
  end
end
