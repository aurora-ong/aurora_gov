defmodule AuroraGov.Storage.Adapter do
  @moduledoc """
  Behaviour for file storage adapters.
  """
  @callback put_file(binary(), String.t(), String.t()) :: {:ok, String.t()} | {:error, term()}
end
