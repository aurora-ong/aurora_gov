defmodule AuroraGov.Command.UpdateOUAvatar do
  use AuroraGov.Command,
    gov_power: [
      id: "org.ou.avatar.update",
      name: "Actualizar avatar de la unidad",
      description: "Permite modificar el logotipo visual de la unidad.",
      category: :ou
    ],
    fields: [
      ou_id: [
        command_type: :string,
        label: "Unidad Organizacional",
        form_type: :text,
        source: {:context, :end_ou_id}
      ],
      ou_avatar_url: [
        command_type: :string,
        label: "Avatar de la Unidad",
        description: "Archivo de imagen cargado para representar visualmente la unidad.",
        form_type: :image_upload,
        source: :user,
        upload_options: [accept: ~w(.png .jpg .jpeg), max_entries: 1, auto_upload: true]
      ],
      file_hash: [
        command_type: :string,
        label: "Integridad del Archivo (Hash)",
        form_type: :hidden,
        source: :internal
      ]
    ]

  def handle_validate(changeset, opts) do
    uploads = Keyword.get(opts, :uploads, [])

    changeset =
      Enum.reduce(uploads, changeset, fn
        {:ou_avatar_url, url, hash}, acc ->
          acc
          |> put_change(:ou_avatar_url, url)
          |> put_change(:file_hash, hash)

        _, acc ->
          acc
      end)

    changeset
    |> validate_required([:ou_id])
  end
end
