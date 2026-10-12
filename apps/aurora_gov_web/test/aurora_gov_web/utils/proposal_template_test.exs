defmodule AuroraGov.Web.Utils.ProposalTemplateTest do
  use ExUnit.Case, async: false

  alias AuroraGov.Web.Utils.ProposalTemplate

  setup do
    {:ok, _} = Application.ensure_all_started(:aurora_gov)
    {:ok, _} = Application.ensure_all_started(:aurora_gov_web)
    :ok
  end

  describe "ProposalTemplate.truncate/2" do
    test "returns the original string if length is within max_len" do
      assert ProposalTemplate.truncate("Corta", 10) == "Corta"
      assert ProposalTemplate.truncate("Exacto", 6) == "Exacto"
    end

    test "truncates and appends ellipsis when exceeding max_len" do
      result = ProposalTemplate.truncate("Esta cadena es bastante larga y debe ser truncada", 20)
      assert String.length(result) == 20
      assert String.ends_with?(result, "...")
    end

    test "handles nil and edge cases safely" do
      assert ProposalTemplate.truncate(nil, 10) == ""
      assert ProposalTemplate.truncate(123, 10) == "123"
    end
  end

  describe "ProposalTemplate helper fallback formatting" do
    test "formats person_name when entity is not found or nil" do
      assert ProposalTemplate.person_name("unknown_123") == "unknown_123"
      assert ProposalTemplate.person_name(nil) == "Persona"
    end

    test "formats ou_name when entity is not found or nil" do
      assert ProposalTemplate.ou_name("unknown_ou") == "unknown_ou"
      assert ProposalTemplate.ou_name(nil) == "Unidad"
    end

    test "formats role_name when entity is not found or nil" do
      assert ProposalTemplate.role_name("unknown_role") == "unknown_role"
      assert ProposalTemplate.role_name(nil) == "Rol"
    end

    test "formats project_name when entity is not found or nil" do
      assert ProposalTemplate.project_name("unknown_project") == "unknown_project"
      assert ProposalTemplate.project_name(nil) == "Proyecto"
    end

    test "formats task_name when entity is not found or nil" do
      assert ProposalTemplate.task_name("unknown_task") == "unknown_task"
      assert ProposalTemplate.task_name(nil) == "Tarea"
    end
  end

  describe "ProposalTemplate.generate_default_proposal/3" do
    test "generates tailored proposal for org.membership.demote" do
      proposal =
        ProposalTemplate.generate_default_proposal(
          "org.membership.demote",
          %{person_id: "usr_456"},
          %{end_ou_id: "ou_barrio"}
        )

      assert proposal.title =~ "Degradar membresía:"
      assert proposal.description =~ "degradar la membresía"
      assert String.length(proposal.title) >= 5 and String.length(proposal.title) <= 60
      assert String.length(proposal.description) >= 10 and String.length(proposal.description) <= 1000
    end

    test "generates tailored proposal for org.membership.promote" do
      proposal =
        ProposalTemplate.generate_default_proposal(
          "org.membership.promote",
          %{person_id: "usr_456"},
          %{end_ou_id: "ou_barrio"}
        )

      assert proposal.title =~ "Promover membresía:"
      assert proposal.description =~ "promover la membresía"
      assert String.length(proposal.title) >= 5 and String.length(proposal.title) <= 60
    end

    test "generates tailored proposal for org.membership.revoke" do
      proposal =
        ProposalTemplate.generate_default_proposal(
          "org.membership.revoke",
          %{person_id: "usr_456"},
          %{end_ou_id: "ou_barrio"}
        )

      assert proposal.title =~ "Revocar membresía:"
      assert proposal.description =~ "revocar la membresía"
      assert String.length(proposal.title) >= 5 and String.length(proposal.title) <= 60
    end

    test "generates tailored proposal for org.membership.start" do
      proposal =
        ProposalTemplate.generate_default_proposal(
          "org.membership.start",
          %{person_id: "usr_456"},
          %{end_ou_id: "ou_barrio"}
        )

      assert proposal.title =~ "Incorporar miembro:"
      assert proposal.description =~ "incorporar a"
      assert String.length(proposal.title) >= 5 and String.length(proposal.title) <= 60
    end

    test "generates tailored proposal for org.role.assign" do
      proposal =
        ProposalTemplate.generate_default_proposal(
          "org.role.assign",
          %{role_id: "role_1", person_id: "usr_456"},
          %{end_ou_id: "ou_barrio"}
        )

      assert proposal.title =~ "Asignar rol:"
      assert String.length(proposal.title) >= 5 and String.length(proposal.title) <= 60
    end

    test "generates tailored proposal for org.role.unassign" do
      proposal =
        ProposalTemplate.generate_default_proposal(
          "org.role.unassign",
          %{role_id: "role_1", person_id: "usr_456"},
          %{end_ou_id: "ou_barrio"}
        )

      assert proposal.title =~ "Desasignar rol:"
      assert String.length(proposal.title) >= 5 and String.length(proposal.title) <= 60
    end

    test "generates tailored proposal for org.ou.rename" do
      proposal =
        ProposalTemplate.generate_default_proposal(
          "org.ou.rename",
          %{ou_name: "Nuevo Nombre"},
          %{end_ou_id: "ou_barrio"}
        )

      assert proposal.title =~ "Renombrar unidad: Nuevo Nombre"
      assert String.length(proposal.title) >= 5 and String.length(proposal.title) <= 60
    end

    test "generates tailored proposal for org.task.complete" do
      proposal =
        ProposalTemplate.generate_default_proposal(
          "org.task.complete",
          %{task_id: "task_123"},
          %{}
        )

      assert proposal.title =~ "Completar tarea: task_123"
      assert String.length(proposal.title) >= 5 and String.length(proposal.title) <= 60
    end

    test "generates default proposal via fallback for standard power" do
      proposal =
        ProposalTemplate.generate_default_proposal(
          "org.task.abandon",
          %{task_id: "task_1"},
          %{end_ou_id: "ou_barrio"}
        )

      assert is_binary(proposal.title)
      assert is_binary(proposal.description)
      assert String.length(proposal.title) >= 5 and String.length(proposal.title) <= 60
      assert String.length(proposal.description) >= 10
    end
  end
end
