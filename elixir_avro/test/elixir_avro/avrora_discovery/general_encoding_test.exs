defmodule ElixirAvro.AvroraDiscovery.GeneralEncodingTest do
  use ExUnit.Case

  describe "happy path" do
    test "starting with a map with string keys" do
      player_registered = %{
        "player_id" => "a0197acb-2829-42a1-9ac2-b327b62df214",
        "full_name" => "Jannik Sinner",
        "rank" => 4,
        "registration_date" => 19752,
        "sponsor_name" => nil,
        "slams_won" => [
          %{"name" => "Australian Open", "year" => 2024, "surface" => "GREENSET"},
          %{"name" => "Roland Garros", "year" => 2024, "surface" => "CLAY"}
        ]
      }

      assert {:ok, binary} =
               ElixirAvro.AvroraClient.encode_plain(player_registered,
                 schema_name: "atp.players.PlayerRegistered"
               )

      assert {:ok, player_registered} ==
               ElixirAvro.AvroraClient.decode_plain(binary,
                 schema_name: "atp.players.PlayerRegistered"
               )
    end

    test "starting from a map with atom keys" do
      player_registered = %{
        player_id: "a0197acb-2829-42a1-9ac2-b327b62df214",
        full_name: "Jannik Sinner",
        rank: 4,
        registration_date: 19752,
        sponsor_name: nil,
        slams_won: [
          %{name: "Australian Open", year: 2024, surface: "GREENSET"},
          %{name: "Roland Garros", year: 2024, surface: "CLAY"}
        ]
      }

      assert {:ok, _} =
               ElixirAvro.AvroraClient.encode_plain(player_registered,
                 schema_name: "atp.players.PlayerRegistered"
               )
    end

    defmodule PlayerRegistered do
      defstruct [:player_id, :full_name, :rank, :registration_date, :sponsor_name, :slams_won]
    end

    defmodule Slam do
      defstruct [:name, :year, :surface]
    end

    test "starting from a struct" do
      player_registered = %PlayerRegistered{
        player_id: "a0197acb-2829-42a1-9ac2-b327b62df214",
        full_name: "Jannik Sinner",
        rank: 4,
        registration_date: 19752,
        sponsor_name: nil,
        slams_won: [
          %Slam{name: "Australian Open", year: 2024, surface: "GREENSET"},
          %Slam{name: "Roland Garros", year: 2024, surface: "CLAY"}
        ]
      }

      assert {:ok, binary} =
               ElixirAvro.AvroraClient.encode_plain(player_registered,
                 schema_name: "atp.players.PlayerRegistered"
               )

      # Decode will always return map with string keys
      assert {:ok, player_registered} !=
               ElixirAvro.AvroraClient.decode_plain(binary,
                 schema_name: "atp.players.PlayerRegistered"
               )
    end
  end

  describe "ignores additional field that are not in the schema" do
    test "string keys, adding birthday" do
      player_registered = %{
        "player_id" => "a0197acb-2829-42a1-9ac2-b327b62df214",
        "full_name" => "Jannik Sinner",
        "rank" => 4,
        "registration_date" => 19752,
        "sponsor_name" => nil,
        # TODO add inline record
        "slams_won" => [],
        "birthday" => ~D[2001-08-16]
      }

      assert {:ok, _} =
               ElixirAvro.AvroraClient.encode_plain(player_registered,
                 schema_name: "atp.players.PlayerRegistered"
               )
    end

    defmodule PlayerRegisteredWithAdditionalFields do
      defstruct [
        :player_id,
        :full_name,
        :rank,
        :registration_date,
        :sponsor_name,
        :slams_won,
        :birthday
      ]
    end

    test "struct with additional fields" do
      player_registered = %PlayerRegisteredWithAdditionalFields{
        player_id: "a0197acb-2829-42a1-9ac2-b327b62df214",
        full_name: "Jannik Sinner",
        rank: 4,
        registration_date: 19752,
        sponsor_name: nil,
        # TODO add inline record
        slams_won: [],
        birthday: ~D[2001-08-16]
      }

      assert {:ok, _} =
               ElixirAvro.AvroraClient.encode_plain(player_registered,
                 schema_name: "atp.players.PlayerRegistered"
               )
    end
  end

  describe "encode: breaking the contract defined by the schema on logical types" do
    test "not a uuid as expected, it still succeed because avro doesn't validate logical types right now" do
      player_registered = %{
        "player_id" => "123",
        "full_name" => "Jannik Sinner",
        "rank" => 4,
        "registration_date" => 19752,
        "sponsor_name" => nil,
        "slams_won" => []
      }

      assert {:ok, _} =
               ElixirAvro.AvroraClient.encode_plain(player_registered,
                 schema_name: "atp.players.PlayerRegistered"
               )
    end
  end

  describe "encode: breaking the contract defined by the schema on primitive types" do
    test "passing a long instead of an integer for rank" do
      player_registered = %{
        "player_id" => "a0197acb-2829-42a1-9ac2-b327b62df214",
        "full_name" => "Jannik Sinner",
        "rank" => 2_147_483_648,
        "registration_date" => "19752",
        "sponsor_name" => nil,
        "slams_won" => []
      }

      assert ElixirAvro.AvroraClient.encode_plain(player_registered,
               schema_name: "atp.players.PlayerRegistered"
             ) == {
               :error,
               %ErlangError{
                 __exception__: true,
                 original:
                   {:"$avro_encode_error",
                    {:badmatch,
                     {:error, {:type_mismatch, {:avro_primitive_type, "int", []}, 2_147_483_648}}},
                    [record: "atp.players.PlayerRegistered", field: "rank"]},
                 reason: nil
               }
             }
    end

    test "passing a string instead of an integer for registration_date" do
      player_registered = %{
        "player_id" => "a0197acb-2829-42a1-9ac2-b327b62df214",
        "full_name" => "Jannik Sinner",
        "rank" => 4,
        "registration_date" => "19752",
        "sponsor_name" => nil,
        "slams_won" => []
      }

      assert ElixirAvro.AvroraClient.encode_plain(player_registered,
               schema_name: "atp.players.PlayerRegistered"
             ) == {
               :error,
               %ErlangError{
                 original:
                   {:"$avro_encode_error",
                    {:badmatch,
                     {:error,
                      {:type_mismatch, {:avro_primitive_type, "int", [{"logicalType", "date"}]},
                       "19752"}}},
                    [record: "atp.players.PlayerRegistered", field: "registration_date"]},
                 reason: nil
               }
             }
    end

    test "passing nil instead of an string for full_name" do
      player_registered = %{
        "player_id" => "a0197acb-2829-42a1-9ac2-b327b62df214",
        "full_name" => nil,
        "rank" => 4,
        "registration_date" => 19752,
        "sponsor_name" => nil,
        "slams_won" => []
      }

      assert ElixirAvro.AvroraClient.encode_plain(player_registered,
               schema_name: "atp.players.PlayerRegistered"
             ) == {
               :error,
               %ErlangError{
                 __exception__: true,
                 original:
                   {:"$avro_encode_error",
                    {:badmatch,
                     {:error, {:type_mismatch, {:avro_primitive_type, "string", []}, nil}}},
                    [record: "atp.players.PlayerRegistered", field: "full_name"]},
                 reason: nil
               }
             }
    end

    test "not passing an optional field" do
      player_registered = %{
        "player_id" => "a0197acb-2829-42a1-9ac2-b327b62df214",
        "full_name" => "Jannik Sinner",
        "rank" => 4,
        "registration_date" => 19752,
        "slams_won" => []
      }

      assert ElixirAvro.AvroraClient.encode_plain(player_registered,
               schema_name: "atp.players.PlayerRegistered"
             ) ==
               {:error,
                %ErlangError{
                  __exception__: true,
                  original:
                    {:"$avro_encode_error", :required_field_missed,
                     [record: "atp.players.PlayerRegistered", field: "sponsor_name"]},
                  reason: nil
                }}
    end

    # does it break the same for violations in inline records?
    test "inline record: passing a string for year in slam" do
      player_registered = %{
        "player_id" => "a0197acb-2829-42a1-9ac2-b327b62df214",
        "full_name" => "Jannik Sinner",
        "rank" => 4,
        "registration_date" => 19752,
        "sponsor_name" => nil,
        "slams_won" => [%{"name" => "Australian Open", "year" => "2024", "surface" => "GREENSET"}]
      }

      assert ElixirAvro.AvroraClient.encode_plain(player_registered,
               schema_name: "atp.players.PlayerRegistered"
             ) ==
               {
                 :error,
                 %ErlangError{
                   __exception__: true,
                   original: {
                     :"$avro_encode_error",
                     {:badmatch,
                      {:error, {:type_mismatch, {:avro_primitive_type, "int", []}, "2024"}}},
                     [
                       {:record, "atp.players.PlayerRegistered"},
                       {:field, "slams_won"},
                       {:record, "atp.tournaments.Slam"},
                       {:field, "year"}
                     ]
                   },
                   reason: nil
                 }
               }
    end
  end

  describe "encode: breaking the contract defined by the schema on enum type" do
    test "enum in inline record has an invalid value" do
      player_registered = %{
        "player_id" => "a0197acb-2829-42a1-9ac2-b327b62df214",
        "full_name" => "Jannik Sinner",
        "rank" => 4,
        "registration_date" => 19752,
        "sponsor_name" => nil,
        "slams_won" => [
          %{"name" => "Cormano Open", "year" => 2020, "surface" => "BLUE"}
        ]
      }

      assert ElixirAvro.AvroraClient.encode_plain(player_registered,
               schema_name: "atp.players.PlayerRegistered"
             ) == {
               :error,
               %ErlangError{
                 original:
                   {:"$avro_encode_error", :function_clause,
                    [
                      record: "atp.players.PlayerRegistered",
                      field: "slams_won",
                      record: "atp.tournaments.Slam",
                      field: "surface"
                    ]},
                 reason: nil
               }
             }
    end
  end

  describe "encode: breaking the contract defined by the schema on array type" do
    test "array field as string value" do
      player_registered = %{
        "player_id" => "a0197acb-2829-42a1-9ac2-b327b62df214",
        "full_name" => "Jannik Sinner",
        "rank" => 4,
        "registration_date" => 19752,
        "sponsor_name" => nil,
        "slams_won" => "empty"
      }

      assert ElixirAvro.AvroraClient.encode_plain(player_registered,
               schema_name: "atp.players.PlayerRegistered"
             ) ==
               {:error,
                %ErlangError{
                  __exception__: true,
                  original:
                    {:"$avro_encode_error", :badarg,
                     [record: "atp.players.PlayerRegistered", field: "slams_won"]},
                  reason: nil
                }}
    end
  end

  # so what do we need between our domain entities (structs or maps) and AvroraClient.encode?

  # let's see what happens with nested records
  # test "nested record" do
  #   player_registered = %{
  #     "player_id" => "a0197acb-2829-42a1-9ac2-b327b62df214",
  #     "full_name" => "Jannik Sinner",
  #     "rank" => 4,
  #     "registration_date" => ~D[2024-01-30],
  #     "slams_won" => []
  #   }
  # end

  @doc """


  # validation when I create the message entity

  # We would like to have a struct and a new function

  # in player_registered.ex
  @spec encode(__MODULE__.t()) :: binary()
  @spec encode_plain(__MODULE__.t()) :: binary()

  defp to_primitive(struct) do
    # sostituire i valori che non sono validi per avrora
    # con tipi validi per avrora
    # es: ~D[2024-01-30] deve diventare 19534
    # e inoltre applichiamo anche la validazione sui logical type dove il tipo elixir coincide con quello che vuole avrora
    # es: uuid chiamiamo UUID.info() e controlliamo che ritorni {:ok, _}

    # per far questo sfruttiamo il parsing dello schema con erlavro
    # e nel template ..
  end

  # in questo caso map puo' essere
  defp from_primitive(map | struct)


  PlayerRegistered.encode_plain(
    %{
          "player_id" => "a0197acb-2829-42a1-9ac2-b327b62df214",
          "full_name" => "Jannik Sinner",
          "rank" => 4,
          "registration_date" => ~D[2024-01-30],
          "slams_won" => []
        },
        format: avro_format
  ) -> restituisce il binario

  PlayerRegistered.encode_plain(
    %{
          "player_id" => "a0197acb-2829-42a1-9ac2-b327b62df214",
          "full_name" => "Jannik Sinner",
          "rank" => 4,
          "registration_date" => ~D[2024-01-30],
          "slams_won" => []
        },
        format: avro_format
  ) -> restituisce il binario

  """
end
