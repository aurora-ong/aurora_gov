defmodule AuroraGov.Storage.Local do
  @behaviour AuroraGov.Storage.Adapter
  
  @impl true
  def put_file(binary_content, filename, _content_type) do
    dest_dir = Path.join([:code.priv_dir(:aurora_gov_web), "static", "uploads"])
    File.mkdir_p!(dest_dir)
    
    unique_filename = "#{Ecto.UUID.generate()}-#{filename}"
    dest_path = Path.join(dest_dir, unique_filename)
    
    case File.write(dest_path, binary_content) do
      :ok -> {:ok, "/uploads/#{unique_filename}"}
      {:error, reason} -> {:error, reason}
    end
  end
end
