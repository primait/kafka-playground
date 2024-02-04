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

  test "two levels of inline record" do
    assert %{
             "Atp.Players.PlayerRegisteredTwoLevelsNestingRecords" => player_registered2_module_content(),
             "Atp.Players.Trainer" => trainer_module_content(),
             "Atp.Players.Info.BirthInfo" => birth_info_module_content(),
             "Atp.Players.Info.Person" => person_module_content()
           } ==
             ContentGenerator.modules_content_from_schema(schema2())
  end

  defp player_registered_module_content() do
    File.read!(Path.join(__DIR__, "#{@expectations_folder}/player_registered"))
  end

  defp player_registered2_module_content() do
    File.read!(Path.join(__DIR__, "#{@expectations_folder}/player_registered_two_levels_nested_records"))
  end

  defp trainer_module_content() do
    File.read!(Path.join(__DIR__, "#{@expectations_folder}/trainer"))
  end

  defp birth_info_module_content() do
    File.read!(Path.join(__DIR__, "#{@expectations_folder}/birth_info"))
  end

  defp person_module_content() do
    File.read!(Path.join(__DIR__, "#{@expectations_folder}/person"))
  end

  defp schema() do
    File.read!(Path.join(__DIR__, "#{@schemas_folder}/player_registered.avsc"))
  end

  defp schema2() do
    File.read!(Path.join(__DIR__, "#{@schemas_folder}/player_registered_two_levels_nested_records.avsc"))
  end
end
