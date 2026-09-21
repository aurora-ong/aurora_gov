defmodule AuroraGov.Context.GlobalSearch do
  import Ecto.Query
  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.{Person, OU, Proposal, Project, Ledger, OURole}

  @search_limit 3

  def search(query) when is_binary(query) and byte_size(query) > 1 do
    search_term = "%#{query}%"
    
    tasks = [
      Task.async(fn -> search_persons(search_term) end),
      Task.async(fn -> search_ous(search_term) end),
      Task.async(fn -> search_proposals(search_term) end),
      Task.async(fn -> search_projects(search_term) end),
      Task.async(fn -> search_ledgers(search_term) end),
      Task.async(fn -> search_roles(search_term) end)
    ]

    tasks
    |> Task.await_many()
    |> List.flatten()
    |> Enum.group_by(& &1.category)
  end

  def search(_), do: %{}

  defp search_persons(term) do
    Person
    |> where([p], ilike(p.person_name, ^term) or ilike(p.person_id, ^term))
    |> limit(@search_limit)
    |> Repo.all()
    |> Enum.map(&%{
      category: "Personas",
      id: &1.person_id,
      title: &1.person_name,
      subtitle: &1.person_id,
      icon: "fa-user",
      url: "/app/members/#{URI.encode_www_form(&1.person_id)}"
    })
  end

  defp search_ous(term) do
    OU
    |> where([o], ilike(o.ou_name, ^term) or ilike(o.ou_id, ^term))
    |> limit(@search_limit)
    |> Repo.all()
    |> Enum.map(&%{
      category: "Unidades",
      id: &1.ou_id,
      title: &1.ou_name,
      subtitle: "Unidad",
      icon: "fa-sitemap",
      url: "/app/home?context=#{URI.encode_www_form(&1.ou_id)}"
    })
  end

  defp search_proposals(term) do
    Proposal
    |> where([p], ilike(p.proposal_title, ^term) or ilike(p.proposal_id, ^term))
    |> limit(@search_limit)
    |> Repo.all()
    |> Enum.map(&%{
      category: "Propuestas",
      id: &1.proposal_id,
      title: &1.proposal_title,
      subtitle: "Propuesta",
      icon: "fa-file-signature",
      url: "/app/proposals/#{URI.encode_www_form(&1.proposal_id)}"
    })
  end

  defp search_projects(term) do
    Project
    |> where([p], ilike(p.name, ^term) or ilike(p.project_id, ^term))
    |> limit(@search_limit)
    |> Repo.all()
    |> Enum.map(&%{
      category: "Proyectos",
      id: &1.project_id,
      title: &1.name,
      subtitle: "Proyecto",
      icon: "fa-diagram-project",
      url: "/app/projects/#{URI.encode_www_form(&1.project_id)}"
    })
  end

  defp search_ledgers(term) do
    Ledger
    |> where([l], ilike(l.name, ^term) or ilike(l.ledger_id, ^term))
    |> limit(@search_limit)
    |> Repo.all()
    |> Enum.map(&%{
      category: "Cuentas",
      id: &1.ledger_id,
      title: &1.name,
      subtitle: "Cuenta (#{&1.ledger_type})",
      icon: "fa-wallet",
      url: "/app/ledger/#{URI.encode_www_form(&1.ledger_id)}"
    })
  end

  defp search_roles(term) do
    OURole
    |> where([r], ilike(r.role_name, ^term) or ilike(r.role_description, ^term))
    |> limit(@search_limit)
    |> Repo.all()
    |> Enum.map(&%{
      category: "Roles",
      id: &1.role_id,
      title: &1.role_name,
      subtitle: "Rol en #{&1.ou_id}",
      icon: "fa-user-tie",
      url: "/app/home?context=#{URI.encode_www_form(&1.ou_id)}"
    })
  end
end

