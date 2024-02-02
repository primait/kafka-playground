defmodule ElixirAvro.Generator.ContentGeneratorTest do
  use ExUnit.Case

  alias ElixirAvro.Generator.ContentGenerator

  describe "generate module" do
    test "inline record" do
      assert %{
               "Atp.Players.PlayerRegistered" => player_registered_module_content(),
               "Atp.Players.Trainer" => trainer_module_content()
             } ==
              ContentGenerator.schema_content_to_modules_content(schema_content())
    end
  end

  defp player_registered_module_content() do
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

    `trainer`: Current trainer.

  """

  use TypedStruct

  typedstruct do
    field :player_id, String.t(), enforce: true
    field :full_name, String.t(), enforce: true
    field :rank, integer(), enforce: true
    field :registration_date, Date.t(), enforce: true
    field :sponsor_name, String.t()
    field :trainer, Atp.Players.Trainer.t(), enforce: true
  end

  def to_avro_map(%__MODULE__{} = r) do
    %{
      "player_id" => r.player_id,
      "full_name" => r.full_name,
      "rank" => r.rank,
      "registration_date" => Date.to_iso8601(r.registration_date),
      "sponsor_name" => r.sponsor_name,
      "trainer" =>
        case r.trainer do
          %Atp.Players.Trainer{} ->
            Atp.Players.Trainer.to_avro_map(r.trainer)

          _ ->
            raise "Invalid type for r.trainer"
        end
    }
  end
end
/
  end

  defp trainer_module_content() do
    ""
  end

  defp schema_content() do
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
        },
        {
          "name": "trainer",
          "type": {
              "name": "Trainer",
              "type": "record",
              "fields": [
                  {
                      "name": "fullname",
                      "type": "string"
                  }
              ]
          },
          "doc": "Current trainer."
        }
      ]
    }
    """
  end
end
