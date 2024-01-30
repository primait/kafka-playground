defmodule Prova do
  alias ElixirBrod.Avro.ModuleWriter.Conventions
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

  {:ok, metadata} =
    SchemaParser.parse(
      File.read!("./schemas/ticketing_system/TicketOpened.avsc"),
      "generated_types"
    )

  write_module = fn m ->
    file = Conventions.generate_path!(m)
    File.mkdir_p!(Path.dirname(file))
    File.write(file, Metadata.to_string(m) |> IO.inspect(label: "to string"))

    Code.compile_file(file)
  end

  write_module.(metadata)

  Enum.filter(metadata.fields, fn
    %{type: {:record, _}} -> true
    _ -> false
  end)
  |> Enum.each(
    &write_module.(ElixirBrod.Avro.SchemaParser.Record.from_field(&1, metadata.base_path))
  )

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

    {:ok, requester_struct} =
      ElixirBrod.GeneratedTypes.TicketingSystem.TicketOpened.create(message)

    {:ok, encoded} =
      Avrora.encode_plain(requester_struct, schema_name: "ticketing_system.TicketOpened")

    {:ok, decoded} = Avrora.decode_plain(encoded, schema_name: "ticketing_system.TicketOpened")
    {:ok, decoded_struct} = ElixirBrod.GeneratedTypes.TicketingSystem.TicketOpened.create(decoded)

    (requester_struct == decoded_struct && "Equal") || "Not equal"
  end
end
