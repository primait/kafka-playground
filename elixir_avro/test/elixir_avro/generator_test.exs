defmodule ElixirAvro.GeneratorTest do
  use ExUnit.Case

  alias ElixirAvro.Generator.Generator

  describe "generate module" do
    test "two primitive fields" do
      assert module_content_two_primitive_fields() ==
               Generator.schema_content_to_module_content(schema_content_two_primitive_fields())
    end
  end

  defp module_content_two_primitive_fields() do
    ~S/defmodule Atp.Players.PlayerRegistered do
  @moduledoc """
  DO NOT EDIT MANUALLY: This module was automatically generated from an AVRO schema.

  A new player is registered in the atp ranking system.

  Fields:

    `player_id`: The unique identifier of the registered player (UUID).

    `full_name`: The full name of the registered player.

    `rank`: The current ranking of the registered player, start counting from 1.

    `registration_date`: The date when the player was registered (number of UTC days
      from the unix epoch).

    `sponsor_name`: The name of the current sponsor (optional).

  """

  use TypedStruct

  typedstruct do
    field :player_id, String.t(), enforce: true
    field :full_name, String.t(), enforce: true
    field :rank, integer(), enforce: true
    field :registration_date, Date.t(), enforce: true
    field :sponsor_name, String.t()
  end

  def to_avro_map(%__MODULE__{} = r) do
    %{
      "player_id" => r.player_id,
      "full_name" => r.full_name,
      "rank" => r.rank,
      "registration_date" => Date.to_iso8601(r.registration_date),
      "sponsor_name" => r.sponsor_name
    }
  end
end
/
  end

  defp schema_content_two_primitive_fields() do
    """
    {
      "doc": "A new player is registered in the atp ranking system.",
      "type": "record",
      "name": "PlayerRegistered",
      "namespace": "atp.players",
      "fields": [
        {
          "name": "player_id",
          "type": {
            "type": "string",
            "logicalType": "uuid"
          },
          "doc": "The unique identifier of the registered player (UUID)."
        },
        {
          "name": "full_name",
          "type": "string",
          "doc": "The full name of the registered player."
        },
        {
          "name": "rank",
          "type": "int",
          "doc": "The current ranking of the registered player, start counting from 1."
        },
        {
          "name": "registration_date",
          "type": {
              "type": "int",
              "logicalType": "date"
          },
          "doc": "The date when the player was registered (number of UTC days from the unix epoch)."
        },
        {
          "name": "sponsor_name",
          "type": [
              "null",
              "string"
          ],
          "doc": "The name of the current sponsor (optional)."
        }
      ]
    }
    """
  end
end
