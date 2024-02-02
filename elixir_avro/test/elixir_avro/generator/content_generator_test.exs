defmodule ElixirAvro.Generator.ContentGeneratorTest do
  use ExUnit.Case

  @expectations_folder "expectations"
  @schemas_folder "schemas"

  alias ElixirAvro.Generator.ContentGenerator

  test "inline record" do
    assert %{
             "Atp.Players.PlayerRegistered" => player_registered_module_content(),
             "Atp.Players.Trainer" => trainer_module_content()
           } ==
             ContentGenerator.modules_content_from_schema(schema())
  end

  defp player_registered_module_content() do
    File.read!(Path.join(__DIR__, "#{@expectations_folder}/player_registered"))
  end

  defp trainer_module_content() do
    File.read!(Path.join(__DIR__, "#{@expectations_folder}/trainer"))
  end

  defp schema() do
    File.read!(Path.join(__DIR__, "#{@schemas_folder}/player_registered.avsc"))
  end
end
