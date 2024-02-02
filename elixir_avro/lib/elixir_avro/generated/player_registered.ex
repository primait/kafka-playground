defmodule Atp.Players.PlayerRegistered do
  @moduledoc """
  DO NOT EDIT MANUALLY: This module was automatically generated from an AVRO schema.

  A new player is registered in the atp ranking system.

  Fields:

    `player_id`: The unique identifier of the registered player (UUID).

  """

  use TypedStruct

  typedstruct do
    field :player_id, String.t(), enforce: true
  end

end
