defmodule AuroraGov.Web.Utils.ProposalTemplate do
  @moduledoc """
  Funciones para generar títulos y descripciones sugeridos de propuestas,
  resolución de nombres legibles e internacionalización mediante Gettext.
  """
  use Gettext, backend: AuroraGov.Web.Gettext

  alias AuroraGov.Context.{
    PersonContext,
    OUContext,
    RoleContext,
    ProjectContext,
    LedgerContext,
    GovPowerContext
  }

  @doc """
  Resuelve el nombre visible de una persona a partir de su ID.
  """
  def person_name(nil), do: dgettext("proposals", "Persona")

  def person_name(person_id) do
    try do
      case PersonContext.get_person(person_id) do
        %{person_name: name} when is_binary(name) and name != "" -> name
        _ -> person_id
      end
    rescue
      _ -> person_id
    end
  end

  @doc """
  Resuelve el nombre visible de una unidad organizacional a partir de su ID.
  """
  def ou_name(nil), do: dgettext("proposals", "Unidad")

  def ou_name(ou_id) do
    try do
      case OUContext.get_ou(ou_id) do
        %{ou_name: name} when is_binary(name) and name != "" -> name
        _ -> ou_id
      end
    rescue
      _ -> ou_id
    end
  end

  @doc """
  Resuelve el nombre visible de un rol a partir de su ID.
  """
  def role_name(nil), do: dgettext("proposals", "Rol")

  def role_name(role_id) do
    try do
      case RoleContext.get_role(role_id) do
        %{role_name: name} when is_binary(name) and name != "" -> name
        _ -> role_id
      end
    rescue
      _ -> role_id
    end
  end

  @doc """
  Resuelve el nombre visible de un proyecto a partir de su ID.
  """
  def project_name(nil), do: dgettext("proposals", "Proyecto")

  def project_name(project_id) do
    try do
      case ProjectContext.get_project(project_id) do
        %{name: name} when is_binary(name) and name != "" -> name
        _ -> project_id
      end
    rescue
      _ -> project_id
    end
  end

  @doc """
  Resuelve el nombre visible de una tarea a partir de su ID.
  """
  def task_name(nil), do: dgettext("proposals", "Tarea")

  def task_name(task_id) do
    try do
      case ProjectContext.get_task(task_id) do
        %{name: name} when is_binary(name) and name != "" -> name
        _ -> task_id
      end
    rescue
      _ -> task_id
    end
  end

  @doc """
  Resuelve el nombre visible de un recurso contable a partir de su ID.
  """
  def resource_name(nil), do: dgettext("proposals", "Recurso")

  def resource_name(resource_id) do
    try do
      case LedgerContext.get_resource(resource_id) do
        %{name: name} when is_binary(name) and name != "" -> name
        _ -> resource_id
      end
    rescue
      _ -> resource_id
    end
  end

  @doc """
  Resuelve el nombre visible de un libro contable a partir de su ID.
  """
  def ledger_name(nil), do: dgettext("proposals", "Cuenta")

  def ledger_name(ledger_id) do
    try do
      case LedgerContext.get_ledger(ledger_id) do
        %{name: name} when is_binary(name) and name != "" -> name
        _ -> ledger_id
      end
    rescue
      _ -> ledger_id
    end
  end

  @doc """
  Trunca una cadena de texto al tamaño máximo permitido, añadiendo '...' si lo excede.
  """
  def truncate(nil, _limit), do: ""

  def truncate(str, limit) when is_binary(str) do
    if String.length(str) > limit do
      String.slice(str, 0, max(0, limit - 3)) <> "..."
    else
      str
    end
  end

  def truncate(other, limit), do: truncate(to_string(other), limit)

  @doc """
  Genera el título y descripción sugeridos para una propuesta a partir del ID del poder,
  los datos del comando y el contexto de la propuesta.
  """
  def generate_default_proposal(power_id, data, context \\ %{})

  # Membresías
  def generate_default_proposal("org.membership.demote", data, context) do
    person_id = get_val(data, :person_id)
    ou_id = get_val(data, :ou_id) || get_val(context, :end_ou_id)
    person = person_name(person_id)
    ou = ou_name(ou_id)

    title =
      dgettext("proposals", "Degradar membresía: %{person_name}", person_name: person)
      |> truncate(60)

    description =
      dgettext(
        "proposals",
        "Se propone degradar la membresía de %{person_name} en %{ou_name} hacia un estamento inferior.",
        person_name: person,
        ou_name: ou
      )
      |> truncate(1000)

    %{title: title, description: description}
  end

  def generate_default_proposal("org.membership.downgrade", data, context) do
    generate_default_proposal("org.membership.demote", data, context)
  end

  def generate_default_proposal("org.membership.promote", data, context) do
    person_id = get_val(data, :person_id)
    ou_id = get_val(data, :ou_id) || get_val(context, :end_ou_id)
    person = person_name(person_id)
    ou = ou_name(ou_id)

    title =
      dgettext("proposals", "Promover membresía: %{person_name}", person_name: person)
      |> truncate(60)

    description =
      dgettext(
        "proposals",
        "Se propone promover la membresía de %{person_name} en %{ou_name} hacia el siguiente rango de participación.",
        person_name: person,
        ou_name: ou
      )
      |> truncate(1000)

    %{title: title, description: description}
  end

  def generate_default_proposal("org.membership.revoke", data, context) do
    person_id = get_val(data, :person_id)
    ou_id = get_val(data, :ou_id) || get_val(context, :end_ou_id)
    person = person_name(person_id)
    ou = ou_name(ou_id)

    title =
      dgettext("proposals", "Revocar membresía: %{person_name}", person_name: person)
      |> truncate(60)

    description =
      dgettext(
        "proposals",
        "Se propone revocar la membresía de %{person_name} en %{ou_name}, cancelando su participación en esta unidad.",
        person_name: person,
        ou_name: ou
      )
      |> truncate(1000)

    %{title: title, description: description}
  end

  def generate_default_proposal("org.membership.start", data, context) do
    person_id = get_val(data, :person_id)
    ou_id = get_val(data, :ou_id) || get_val(context, :end_ou_id)
    person = person_name(person_id)
    ou = ou_name(ou_id)

    title =
      dgettext("proposals", "Incorporar miembro: %{person_name}", person_name: person)
      |> truncate(60)

    description =
      dgettext(
        "proposals",
        "Se propone incorporar a %{person_name} como miembro activo en %{ou_name}.",
        person_name: person,
        ou_name: ou
      )
      |> truncate(1000)

    %{title: title, description: description}
  end

  # Roles
  def generate_default_proposal("org.role.assign", data, _context) do
    role_id = get_val(data, :role_id)
    person_id = get_val(data, :person_id)
    role = role_name(role_id)
    person = person_name(person_id)

    title =
      dgettext("proposals", "Asignar rol: %{role_name} a %{person_name}",
        role_name: role,
        person_name: person
      )
      |> truncate(60)

    description =
      dgettext("proposals", "Se propone asignar el rol de %{role_name} a %{person_name}.",
        role_name: role,
        person_name: person
      )
      |> truncate(1000)

    %{title: title, description: description}
  end

  def generate_default_proposal("org.role.unassign", data, _context) do
    role_id = get_val(data, :role_id)
    person_id = get_val(data, :person_id)
    role = role_name(role_id)
    person = person_name(person_id)

    title =
      dgettext("proposals", "Desasignar rol: %{role_name} de %{person_name}",
        role_name: role,
        person_name: person
      )
      |> truncate(60)

    description =
      dgettext("proposals", "Se propone desasignar el rol de %{role_name} de %{person_name}.",
        role_name: role,
        person_name: person
      )
      |> truncate(1000)

    %{title: title, description: description}
  end

  def generate_default_proposal("org.role.create", data, context) do
    ou_id = get_val(data, :ou_id) || get_val(context, :end_ou_id)
    ou = ou_name(ou_id)
    role_name = get_val(data, :role_name) || "nuevo rol"

    title =
      dgettext("proposals", "Crear rol: %{role_name}", role_name: role_name)
      |> truncate(60)

    description =
      dgettext(
        "proposals",
        "Se propone la creación del rol '%{role_name}' en la unidad organizacional %{ou_name}.",
        role_name: role_name,
        ou_name: ou
      )
      |> truncate(1000)

    %{title: title, description: description}
  end

  def generate_default_proposal("org.role.archive", data, context) do
    role_id = get_val(data, :role_id)
    ou_id = get_val(data, :ou_id) || get_val(context, :end_ou_id)
    role = role_name(role_id)
    ou = ou_name(ou_id)

    title =
      dgettext("proposals", "Archivar rol: %{role_name}", role_name: role)
      |> truncate(60)

    description =
      dgettext(
        "proposals",
        "Se propone archivar el rol %{role_name} en la unidad organizacional %{ou_name}.",
        role_name: role,
        ou_name: ou
      )
      |> truncate(1000)

    %{title: title, description: description}
  end

  # Unidades Organizacionales
  def generate_default_proposal("org.ou.create", data, _context) do
    name = get_val(data, :ou_name) || "nueva unidad"

    title =
      dgettext("proposals", "Crear unidad: %{ou_name}", ou_name: name)
      |> truncate(60)

    description =
      dgettext(
        "proposals",
        "Se propone la creación de una nueva unidad organizacional denominada '%{ou_name}'.",
        ou_name: name
      )
      |> truncate(1000)

    %{title: title, description: description}
  end

  def generate_default_proposal("org.ou.rename", data, context) do
    ou_id = get_val(data, :ou_id) || get_val(context, :end_ou_id)
    ou = ou_name(ou_id)
    new_name = get_val(data, :ou_name) || "nuevo nombre"

    title =
      dgettext("proposals", "Renombrar unidad: %{new_name}", new_name: new_name)
      |> truncate(60)

    description =
      dgettext(
        "proposals",
        "Se propone renombrar la unidad organizacional %{ou_name} a %{new_name}.",
        ou_name: ou,
        new_name: new_name
      )
      |> truncate(1000)

    %{title: title, description: description}
  end

  def generate_default_proposal("org.ou.goal.update", data, context) do
    ou_id = get_val(data, :ou_id) || get_val(context, :end_ou_id)
    ou = ou_name(ou_id)
    goal = get_val(data, :ou_goal)

    title =
      dgettext("proposals", "Actualizar objetivo: %{ou_name}", ou_name: ou)
      |> truncate(60)

    description =
      if goal && goal != "" do
        dgettext("proposals", "Se propone actualizar el objetivo de %{ou_name} a: %{goal}.",
          ou_name: ou,
          goal: goal
        )
      else
        dgettext(
          "proposals",
          "Se propone actualizar el objetivo estratégico de la unidad organizacional %{ou_name}.",
          ou_name: ou
        )
      end
      |> truncate(1000)

    %{title: title, description: description}
  end

  # Proyectos y Tareas
  def generate_default_proposal("org.project.create", data, context) do
    ou_id = get_val(data, :ou_id) || get_val(context, :end_ou_id)
    ou = ou_name(ou_id)
    name = get_val(data, :name) || "Nuevo proyecto"
    desc = get_val(data, :description)

    title =
      dgettext("proposals", "Crear proyecto: %{project_name}", project_name: name)
      |> truncate(60)

    description =
      if desc && desc != "" do
        dgettext(
          "proposals",
          "Se propone la creación del proyecto %{project_name} en %{ou_name}: %{description}",
          project_name: name,
          ou_name: ou,
          description: desc
        )
      else
        dgettext(
          "proposals",
          "Se propone la creación del proyecto %{project_name} en la unidad %{ou_name}.",
          project_name: name,
          ou_name: ou
        )
      end
      |> truncate(1000)

    %{title: title, description: description}
  end

  def generate_default_proposal("org.task.create", data, _context) do
    project_id = get_val(data, :project_id)
    project = project_name(project_id)
    name = get_val(data, :name) || "Nueva tarea"
    goal = get_val(data, :goal)

    title =
      dgettext("proposals", "Crear tarea: %{task_name}", task_name: name)
      |> truncate(60)

    description =
      if goal && goal != "" do
        dgettext(
          "proposals",
          "Se propone crear la tarea %{task_name} en el proyecto %{project_name}. Objetivo: %{goal}.",
          task_name: name,
          project_name: project,
          goal: goal
        )
      else
        dgettext(
          "proposals",
          "Se propone crear la tarea %{task_name} en el proyecto %{project_name}.",
          task_name: name,
          project_name: project
        )
      end
      |> truncate(1000)

    %{title: title, description: description}
  end

  def generate_default_proposal("org.task.assign", data, _context) do
    task_id = get_val(data, :task_id)
    person_id = get_val(data, :person_id)
    task = task_name(task_id)
    person = person_name(person_id)

    title =
      dgettext("proposals", "Asignar tarea: %{task_name} a %{person_name}",
        task_name: task,
        person_name: person
      )
      |> truncate(60)

    description =
      dgettext("proposals", "Se propone asignar la tarea %{task_name} a %{person_name}.",
        task_name: task,
        person_name: person
      )
      |> truncate(1000)

    %{title: title, description: description}
  end

  def generate_default_proposal("org.task.complete", data, _context) do
    task_id = get_val(data, :task_id)
    task = task_name(task_id)

    title =
      dgettext("proposals", "Completar tarea: %{task_name}", task_name: task)
      |> truncate(60)

    description =
      dgettext("proposals", "Se propone dar por completada la tarea %{task_name}.",
        task_name: task
      )
      |> truncate(1000)

    %{title: title, description: description}
  end

  # Recursos y Contabilidad (Ledger)
  def generate_default_proposal("org.resource.create", data, context) do
    ou_id = get_val(data, :ou_id) || get_val(context, :end_ou_id)
    ou = ou_name(ou_id)
    name = get_val(data, :name) || "Nuevo recurso"
    unit = get_val(data, :unit_of_measure) || "unidades"
    desc = get_val(data, :description)

    title =
      dgettext("proposals", "Crear recurso: %{name}", name: name)
      |> truncate(60)

    description =
      if desc && desc != "" do
        dgettext(
          "proposals",
          "Se propone crear el recurso contable '%{name}' (%{unit}) en %{ou_name}: %{description}",
          name: name,
          unit: unit,
          ou_name: ou,
          description: desc
        )
      else
        dgettext(
          "proposals",
          "Se propone crear el recurso contable '%{name}' (%{unit}) en la unidad %{ou_name}.",
          name: name,
          unit: unit,
          ou_name: ou
        )
      end
      |> truncate(1000)

    %{title: title, description: description}
  end

  def generate_default_proposal("org.resource.edit", data, context) do
    ou_id = get_val(data, :ou_id) || get_val(context, :end_ou_id)
    ou = ou_name(ou_id)
    resource_id = get_val(data, :resource_id)
    res_name = get_val(data, :name) || resource_name(resource_id)
    desc = get_val(data, :description)

    title =
      dgettext("proposals", "Editar recurso: %{name}", name: res_name)
      |> truncate(60)

    description =
      if desc && desc != "" do
        dgettext(
          "proposals",
          "Se propone actualizar la información del recurso '%{name}' en %{ou_name}: %{description}",
          name: res_name,
          ou_name: ou,
          description: desc
        )
      else
        dgettext(
          "proposals",
          "Se propone actualizar la información del recurso '%{name}' en la unidad %{ou_name}.",
          name: res_name,
          ou_name: ou
        )
      end
      |> truncate(1000)

    %{title: title, description: description}
  end

  def generate_default_proposal("org.resource.update", data, context) do
    generate_default_proposal("org.resource.edit", data, context)
  end

  def generate_default_proposal("org.ledger.create", data, context) do
    owner_id = get_val(data, :owner_id) || get_val(data, :ou_id) || get_val(context, :end_ou_id)
    ou = ou_name(owner_id)
    account_name = get_val(data, :name) || "Nueva cuenta"
    resource_id = get_val(data, :resource_id)
    res_name = resource_name(resource_id)
    desc = get_val(data, :description)

    title =
      dgettext("proposals", "Aperturar cuenta: %{account_name}", account_name: account_name)
      |> truncate(60)

    description =
      if desc && desc != "" do
        dgettext(
          "proposals",
          "Se propone aperturar la cuenta contable '%{account_name}' asociada al recurso %{resource_name} en %{ou_name}: %{description}",
          account_name: account_name,
          resource_name: res_name,
          ou_name: ou,
          description: desc
        )
      else
        dgettext(
          "proposals",
          "Se propone aperturar la cuenta contable '%{account_name}' asociada al recurso %{resource_name} en la unidad %{ou_name}.",
          account_name: account_name,
          resource_name: res_name,
          ou_name: ou
        )
      end
      |> truncate(1000)

    %{title: title, description: description}
  end

  def generate_default_proposal("org.transaction.record", data, context) do
    ou_id = get_val(data, :ou_id) || get_val(context, :end_ou_id)
    ou = ou_name(ou_id)
    origin_id = get_val(data, :origin_ledger_id)
    dest_id = get_val(data, :destination_ledger_id)
    origin = ledger_name(origin_id)
    destination = ledger_name(dest_id)
    amount = get_val(data, :amount)
    amount_str = if amount && to_string(amount) != "", do: to_string(amount), else: nil
    desc = get_val(data, :description)

    title =
      dgettext("proposals", "Transferencia desde %{origin} a %{destination}",
        amount: amount_str,
        origin: origin,
        destination: destination
      )
      |> truncate(60)

    description =
      if desc && desc != "" do
        dgettext(
          "proposals",
          "Se propone transferir %{amount} desde la cuenta %{origin} hacia %{destination} en %{ou_name}. Motivo: %{description}",
          amount: amount_str || "fondos",
          origin: origin,
          destination: destination,
          ou_name: ou,
          description: desc
        )
      else
        dgettext(
          "proposals",
          "Se propone transferir %{amount} desde la cuenta %{origin} hacia la cuenta %{destination} en la unidad %{ou_name}.",
          amount: amount_str || "fondos",
          origin: origin,
          destination: destination,
          ou_name: ou
        )
      end
      |> truncate(1000)

    %{title: title, description: description}
  end

  # Fallback general para cualquier otro poder
  def generate_default_proposal(power_id, data, context) do
    ou_id = get_val(data, :ou_id) || get_val(context, :end_ou_id)
    ou = ou_name(ou_id)

    power =
      case GovPowerContext.get_gov_power(power_id) do
        {:ok, p} -> p
        _ -> %{name: "Propuesta", description: "Acción de gobernanza"}
      end

    power_name = power.name
    power_desc = power.description || power_name

    title =
      dgettext("proposals", "%{power_name}: %{ou_name}",
        power_name: power_name,
        ou_name: ou
      )
      |> truncate(60)

    description =
      dgettext(
        "proposals",
        "Se propone ejecutar la acción '%{power_name}' en %{ou_name}. %{description}",
        power_name: power_name,
        ou_name: ou,
        description: power_desc
      )
      |> truncate(1000)

    %{title: title, description: description}
  end

  defp get_val(nil, _key), do: nil
  defp get_val(%_{} = struct, key), do: Map.get(struct, key)

  defp get_val(%{} = map, key) do
    Map.get(map, key) || Map.get(map, to_string(key))
  end

  defp get_val(_other, _key), do: nil
end
