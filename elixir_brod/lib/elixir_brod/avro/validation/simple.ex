defmodule ElixirBrod.Avro.Validation.Simple do

  alias ElixirBrod.Avro.SchemaParser.Field
  
  @primitive_types [:boolean, :bytes, :double, :float, :int, :long, :null, :string]

  @logical_types [
     :"local-timestamp-micros",
     :"local-timestamp-millis",
     :"time-micros",
     :"time-millis",
     :"timestamp-micros",
     :"timestamp-millis",
     :date,
     :duration,
     :uuid,
     :decimal
   ]

  @simple_types @primitive_types ++ @logical_types

  def validate({results, data}, name, %Field{type: type} = definition) when type in @simple_types do
    %_{^name => value} = data
    validator = get_validator(definition)
      if validator.(value) do
	{[{:ok, name, value}|results], data}        
      else 
        {[{:error, name, "#{inspect(value)} isn't a valid #{inspect type}"}|results], data}
      end 
  rescue
    _ ->
      {[{:error, name, :field_not_present}|results], data}
  end

  def get_validator(%Field{logical_type: :"local-timestamp-micros"}),
    do: &is_avro_long/1

  def get_validator(%Field{logical_type: "local-timestamp-millis"}),
    do: &is_avro_long/1
  
  def get_validator(%Field{logical_type: :"timestamp-micros"}),
    do: &is_avro_long/1

  def get_validator(%Field{logical_type: :"timestamp-millis"}),
    do: &is_avro_long/1

  def get_validator(%Field{logical_type: :"time-micros"}),
    do: & is_avro_long(&1) && &1 >= 0

  def get_validator(%Field{logical_type: :"time-millis"}),
    do: & is_avro_int(&1) && &1 >= 0

  def get_validator(%Field{logical_type: :date}),
       do: & is_avro_int(&1) && &1 >= 0
    
  def get_validator(%Field{logical_type: :uuid}),
    do: & match?({:ok, _}, UUID.info(&1))

  def get_validator(%Field{logical_type: :decimal}),
    do: &match?(%ElixirBrod.Avro.Type.Duration{}, &1) 

  def get_validator(%Field{logical_type: :duration}),
    do: &match?(%ElixirBrod.Avro.Type.Duration{}, &1)

  def get_validator(:boolean), do: &is_boolean/1

  def get_validator(:bytes), do: &is_binary/1

  def get_validator(:double), do: &is_avro_double/1

  def get_validator(:float), do: &is_avro_float/1

  def get_validator(:int), do: &is_avro_int/1

  def get_validator(:long), do: &is_avro_long/1

  def get_validator(:null), do: &is_nil/1

  def get_validator(:string), do: &String.valid?/1

  def is_avro_float(value),
       do: is_float(value) and value >= -3.4_028_235e38 and value <= 3.4_028_235e38

  def is_avro_double(value),
       do: is_float(value) and value >= -1.7_976_931_348_623_157e308 and value <= 1.7_976_931_348_623_157e308

  def is_avro_int(value),
       do: is_integer(value) and value >= -2_147_483_648 and value <= 2_147_483_647

  def is_avro_long(value),
       do: is_integer(value) and value >= -9_223_372_036_854_775_808 and value <= 9_223_372_036_854_775_807
end
