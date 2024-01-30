defmodule Prova do
  alias ElixirBrod.Avro.ModuleWriter.Metadata
  alias ElixirBrod.Avro.SchemaParser

  def generate_requester_file() do
    {:ok, metadata} =
      SchemaParser.parse(
        File.read!("./schemas/ticketing_system/Requester.avsc"),
        "generated_types"
      )

    module_content = Metadata.to_string(metadata)
    File.write("lib/elixir_brod/requester.ex", module_content)
  end

  def encode_decode() do
    # message=%{email: "fra@prima.it", surname: "zu", name: "fra", age: 5, middlename: nil}
    message = %{
      "email" => "fra@prima.it",
      "surname" => "zu",
      "name" => "fra",
      "age" => 5,
      "middlename" => nil
    }

    {:ok, requester_struct} = ElixirBrod.GeneratedTypes.TicketingSystem.Requester.create(message)

    {:ok, encoded} =
      Avrora.encode_plain(requester_struct, schema_name: "ticketing_system.Requester")

    {:ok, decoded} = Avrora.decode_plain(encoded, schema_name: "ticketing_system.Requester")
    {:ok, decoded_struct} = ElixirBrod.GeneratedTypes.TicketingSystem.Requester.create(decoded)

    (requester_struct == decoded_struct && "Equal") || "Not equal"
  end



  def encode_decode_nested_record() do
    # message=%{email: "fra@prima.it", surname: "zu", name: "fra", age: 5, middlename: nil}
    message = %{
      "ticket_id" => UUID.uuid4(),
      "occurred_on" => DateTime.utc_now(),
      "requester" => %{
        "email" => "fra@prima.it",
        "surname" => "zu",
        "name" => "fra",
        "age" => 5,
        "middlename" => nil
      }
    }

    {:ok, struct} =
      ElixirBrod.GeneratedTypes.TicketingSystem.TicketOpened.create(message)

    {:ok, encoded} =
      Avrora.encode_plain(struct |> IO.inspect(label: "struct"), schema_name: "ticketing_system.TicketOpened")

    {:ok, decoded} = Avrora.decode_plain(encoded, schema_name: "ticketing_system.TicketOpened")
    {:ok, decoded_struct} = ElixirBrod.GeneratedTypes.TicketingSystem.TicketOpened.create(decoded)

    (struct == decoded_struct && "Equal") || "Not equal"
  end
end
