defmodule AuroraGov.Test.Seeds.AuroraSeedTest do
  use AuroraGov.Test.CommandCase, async: false

  import Ecto.Query

  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.{Membership, OU, OURole, OURoleAssignment, Person}

  @seed_path Path.expand("../../../priv/repo/seeds_aurora.exs", __DIR__)

  setup do
    previous_password = System.get_env("AURORA_BETA_DEFAULT_PASSWORD")
    System.put_env("AURORA_BETA_DEFAULT_PASSWORD", "AuroraBetaTest123!")

    on_exit(fn ->
      restore_env("AURORA_BETA_DEFAULT_PASSWORD", previous_password)
    end)

    :ok
  end

  test "carga y verifica la sistematización BETA completa" do
    assert {:ok, _bindings} = Code.eval_file(@seed_path)

    assert Repo.aggregate(OU, :count, :ou_id) == 6
    assert Repo.aggregate(Person, :count, :person_id) == 15
    assert Repo.aggregate(Membership, :count, :person_id) == 42
    assert Repo.aggregate(OURole, :count, :role_id) == 14
    assert Repo.aggregate(OURoleAssignment, :count, :person_id) == 12

    # Regresión de normalización de datos de la planilla.
    assert Repo.get(OU, "aurora.ong.direccion")

    refute Repo.get(OU, "aurora.ong,dirección")
    refute Repo.get(OU, "aurora.ong,direccion")

    # Regla BETA: quien era Miembro/Regular en la fuente sube a Senior.
    assert %Membership{membership_rank: :senior} =
             Repo.get_by(Membership,
               ou_id: "aurora.ong.direccion",
               person_id: "p.delgado@aurora.ong"
             )

    # Regla BETA: quien era Junior en la fuente sube a Regular.
    assert %Membership{membership_rank: :regular} =
             Repo.get_by(Membership,
               ou_id: "aurora.ong.tecnologia",
               person_id: "m.rosales@aurora.ong"
             )

    # Nadie debe quedar Junior en el ambiente BETA.
    assert Repo.aggregate(
             from(m in Membership, where: m.membership_rank == :junior),
             :count,
             :person_id
           ) == 0

    # Pavel, Madeleine y Paola eran Miembro/Regular en la fuente.
    # Pavel tiene cuatro membresías y Madeleine/Paola dos cada una: 8 senior.
    assert Repo.aggregate(
             from(m in Membership, where: m.membership_rank == :senior),
             :count,
             :person_id
           ) == 8

    assert %Membership{membership_rank: :senior} =
             Repo.get_by(Membership,
               ou_id: "aurora.ong.tecnologia",
               person_id: "p.delgado@aurora.ong"
             )


    # Miembros activos sin unidad especializada: solo Aurora + Aurora ONG.
    for {person_id, expected_rank} <- [
          {"m.sanzana@aurora.ong", :senior},
          {"p.smartin@aurora.ong", :senior},
          {"f.urra@aurora.ong", :regular},
          {"t.quiroz@aurora.ong", :regular}
        ] do
      assert Repo.get(Person, person_id)

      memberships =
        from(m in Membership,
          where: m.person_id == ^person_id,
          order_by: m.ou_id,
          select: {m.ou_id, m.membership_rank}
        )
        |> Repo.all()

      assert memberships == [
               {"aurora", expected_rank},
               {"aurora.ong", expected_rank}
             ]
    end

    # Las personas con Fecha Salida no deben formar parte del ambiente BETA.
    for person_id <- [
          "h.montesinos@aurora.ong",
          "v.varela@aurora.ong",
          "a.escobedo@aurora.ong",
          "c.gonzalez@aurora.ong",
          "c.paz@aurora.ong"
        ] do
      refute Repo.get(Person, person_id)
      refute Repo.get_by(Membership, person_id: person_id)
    end

    # Pavel integra Tecnología como Product Owner.
    product_owner = Repo.get!(OURole, "aurora.ong.tecnologia.product_owner")
    assert product_owner.role_name == "Product Owner"

    assert Repo.get_by(OURoleAssignment,
             role_id: product_owner.role_id,
             ou_id: "aurora.ong.tecnologia",
             person_id: "p.delgado@aurora.ong"
           )

    # Rol crítico de la sistematización.
    tech_lead = Repo.get!(OURole, "aurora.ong.tecnologia.tech_lead")
    assert tech_lead.role_name == "Tech Lead"

    assert Repo.get_by(OURoleAssignment,
             role_id: tech_lead.role_id,
             ou_id: "aurora.ong.tecnologia",
             person_id: "m.rosales@aurora.ong"
           )

    # No deben persistir IDs de OU con errores de coma/espacios/tilde.
    malformed =
      from(ou in OU,
        where: like(ou.ou_id, "%,%") or like(ou.ou_id, "% %") or like(ou.ou_id, "%dirección%"),
        select: ou.ou_id
      )
      |> Repo.all()

    assert malformed == []
  end

  defp restore_env(key, nil), do: System.delete_env(key)
  defp restore_env(key, value), do: System.put_env(key, value)
end
