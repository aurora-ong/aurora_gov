defmodule AuroraGov.Storage do
  @moduledoc """
  Public API for file storage, delegating to the configured adapter.
  """
  
  def adapter do
    Application.get_env(:aurora_gov, :storage_adapter, AuroraGov.Storage.Local)
  end
  
  @doc """
  Uploads a file binary to the configured storage and returns the public URL.
  """
  def put_file(binary_content, filename, content_type) do
    adapter().put_file(binary_content, filename, content_type)
  end
end
