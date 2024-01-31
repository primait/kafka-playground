defprotocol ElixirBrod.Avro.ModuleWriter.Metadata do
  @spec to_string(t) :: String.t() | no_return()
  def to_string(metadata)
end
