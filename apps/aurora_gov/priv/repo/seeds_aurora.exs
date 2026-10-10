# Seeds BETA AuroraGov 2026
#
# Fuentes:
#   - Sistematización Demo AuroraGov 2026.xlsx
#   - Registro de miembros(2).xlsx
#
# Este seed está pensado para ejecutarse sobre una base RESETEADA.
# Falla de forma explícita ante cualquier error para evitar ambientes
# parcialmente inicializados.
#
# Variables requeridas:
#   AURORA_BETA_DEFAULT_PASSWORD
#
# Regla BETA de participantes:
#   - Se excluye cualquier persona con Fecha Salida informada en el registro fuente.
#
# Regla BETA de membresías:
#   - Personas Junior en el registro fuente -> Regular en la BETA.
#   - Personas Miembro/Regular en el registro fuente -> Senior en la BETA.
#
# Como StartMembership crea siempre una membresía Junior, el seed promueve
# una vez TODAS las membresías y una segunda vez las personas que en la
# fuente ya tenían calidad de Miembro/Regular.
#
# Nota de datos fuente:
#   La sistematización contiene variantes como "aurora.ong,dirección" y
#   espacios finales. Aquí se normalizan a "aurora.ong.direccion".
#   Además, "Director general" y "Desarrollador Frontend" aparecen asignados
#   pero no definidos en la hoja Roles; sus descripciones quedan marcadas
#   abajo como definiciones complementarias para que el seed sea ejecutable.

defmodule AuroraGov.Seeds.AuroraBeta do
  require Logger

  import Ecto.Query

  alias AuroraGov.Command.{
    AssignRole,
    CreateOU,
    CreateRole,
    PromoteMembership,
    StartMembership
  }

  alias AuroraGov.Context.PersonContext
  alias AuroraGov.Projector.Repo
  alias AuroraGov.Projector.Model.{Membership, OU, OURole, OURoleAssignment, Person}

  @ous [
    %{
      ou_id: "aurora",
      ou_name: "Aurora",
      ou_goal:
        "Impulsar una organización horizontal orientada al bienestar humano y al desarrollo sostenible.",
      ou_description:
        "Unidad raíz que reúne y alinea todo el ecosistema Aurora mediante la inteligencia colectiva."
    },
    %{
      ou_id: "aurora.ong",
      ou_name: "Aurora ONG",
      ou_goal:
        "Implementar y promover el Modelo Aurora mediante proyectos, tecnología y colaboración.",
      ou_description:
        "Organización operativa que materializa los principios de Aurora de forma abierta, participativa y transparente."
    },
    %{
      ou_id: "aurora.ong.direccion",
      ou_name: "Unidad de Dirección",
      ou_goal:
        "Facilitar la coordinación estratégica y el cumplimiento de los objetivos colectivos.",
      ou_description:
        "Articula las unidades y acompaña la toma de decisiones sin concentrar el poder organizacional."
    },
    %{
      ou_id: "aurora.ong.comunicaciones",
      ou_name: "Unidad de Comunicaciones",
      ou_goal: "Comunicar la identidad, los objetivos y las actividades de Aurora.",
      ou_description:
        "Gestiona contenidos, difusión y comunicación interna, promoviendo un lenguaje común y transparente."
    },
    %{
      ou_id: "aurora.ong.tecnologia",
      ou_name: "Unidad de Tecnología",
      ou_goal: "Desarrollar y mantener las herramientas tecnológicas del Modelo Aurora.",
      ou_description:
        "Administra el producto y la infraestructura, asegurando calidad, seguridad, trazabilidad y mejora continua."
    },
    %{
      ou_id: "aurora.ong.financiamiento",
      ou_name: "Unidad de Financiamiento",
      ou_goal: "Obtener y gestionar recursos para la sostenibilidad de Aurora.",
      ou_description:
        "Busca oportunidades de financiamiento y administra los recursos con transparencia y responsabilidad."
    }
  ]

  # Incluimos las personas activas del registro de miembros.
  # Quienes no tienen unidad especializada definida entran únicamente en
  # Aurora y Aurora ONG; su incorporación a una unidad será parte de la BETA.
  # person_id y person_mail usan el correo @aurora.ong para que el login BETA
  # sea predecible y no exponga correos personales secundarios.
  @people [
    %{person_id: "p.delgado@aurora.ong", person_name: "Pavel Andrés Delgado Hurtado", quality: :member},
    %{person_id: "m.sanzana@aurora.ong", person_name: "Madeleine Lorena Sanzana Santos", quality: :member},
    %{person_id: "p.smartin@aurora.ong", person_name: "Paola Andrea San Martín Luna", quality: :member},
    %{person_id: "f.urra@aurora.ong", person_name: "Fernando Abel Urra Soto", quality: :junior},
    %{person_id: "t.quiroz@aurora.ong", person_name: "Tomas Eduardo Quiroz Romero", quality: :junior},
    %{person_id: "u.pinacho@aurora.ong", person_name: "Ulises Fernando Pinacho Brito", quality: :junior},
    %{person_id: "f.carmona@aurora.ong", person_name: "Francisco Javier Carmona Valderrama", quality: :junior},
    %{person_id: "f.vega@aurora.ong", person_name: "Francisco Eduardo Vega Carripan", quality: :junior},
    %{person_id: "l.rodriguez@aurora.ong", person_name: "Leonardo Montaño Rodríguez", quality: :junior},
    %{person_id: "m.ros@aurora.ong", person_name: "María Antonia Ros Ros", quality: :junior},
    %{person_id: "a.castano@aurora.ong", person_name: "Adrián Castaño Calle", quality: :junior},
    %{person_id: "a.fuentes@aurora.ong", person_name: "Aaron Israel Fuentes Diocares", quality: :junior},
    %{person_id: "m.rosales@aurora.ong", person_name: "Mauro Cesar Rosales Baumgartner", quality: :junior},
    %{person_id: "i.rojas@aurora.ong", person_name: "Mateo Ismael Rojas Villacreses", quality: :junior},
    %{person_id: "l.cuenca@aurora.ong", person_name: "Leduin José Cuenca Macas", quality: :junior}
  ]

  # El orden respeta la jerarquía: raíz -> aurora.ong -> unidad especializada.
  # StartMembership exige membresía previa en la unidad padre.
  @memberships [
    # Dirección
    {"aurora", "p.delgado@aurora.ong"},
    {"aurora.ong", "p.delgado@aurora.ong"},
    {"aurora.ong.direccion", "p.delgado@aurora.ong"},
    # Pavel también integra Tecnología como Product Owner.
    {"aurora.ong.tecnologia", "p.delgado@aurora.ong"},

    # Miembros activos sin unidad especializada asignada.
    # En la BETA se propondrá su incorporación a alguna unidad.
    {"aurora", "m.sanzana@aurora.ong"},
    {"aurora.ong", "m.sanzana@aurora.ong"},
    {"aurora", "p.smartin@aurora.ong"},
    {"aurora.ong", "p.smartin@aurora.ong"},
    {"aurora", "f.urra@aurora.ong"},
    {"aurora.ong", "f.urra@aurora.ong"},
    {"aurora", "t.quiroz@aurora.ong"},
    {"aurora.ong", "t.quiroz@aurora.ong"},

    {"aurora", "u.pinacho@aurora.ong"},
    {"aurora.ong", "u.pinacho@aurora.ong"},
    {"aurora.ong.direccion", "u.pinacho@aurora.ong"},
    {"aurora", "f.carmona@aurora.ong"},
    {"aurora.ong", "f.carmona@aurora.ong"},
    {"aurora.ong.direccion", "f.carmona@aurora.ong"},

    # Comunicaciones
    {"aurora", "f.vega@aurora.ong"},
    {"aurora.ong", "f.vega@aurora.ong"},
    {"aurora.ong.comunicaciones", "f.vega@aurora.ong"},
    {"aurora", "l.rodriguez@aurora.ong"},
    {"aurora.ong", "l.rodriguez@aurora.ong"},
    {"aurora.ong.comunicaciones", "l.rodriguez@aurora.ong"},
    {"aurora", "m.ros@aurora.ong"},
    {"aurora.ong", "m.ros@aurora.ong"},
    {"aurora.ong.comunicaciones", "m.ros@aurora.ong"},
    {"aurora", "a.castano@aurora.ong"},
    {"aurora.ong", "a.castano@aurora.ong"},
    {"aurora.ong.comunicaciones", "a.castano@aurora.ong"},

    # Tecnología
    {"aurora", "a.fuentes@aurora.ong"},
    {"aurora.ong", "a.fuentes@aurora.ong"},
    {"aurora.ong.tecnologia", "a.fuentes@aurora.ong"},
    {"aurora", "m.rosales@aurora.ong"},
    {"aurora.ong", "m.rosales@aurora.ong"},
    {"aurora.ong.tecnologia", "m.rosales@aurora.ong"},
    {"aurora", "i.rojas@aurora.ong"},
    {"aurora.ong", "i.rojas@aurora.ong"},
    {"aurora.ong.tecnologia", "i.rojas@aurora.ong"},

    # Financiamiento
    {"aurora", "l.cuenca@aurora.ong"},
    {"aurora.ong", "l.cuenca@aurora.ong"},
    {"aurora.ong.financiamiento", "l.cuenca@aurora.ong"},
  ]

  # role_id es globalmente único porque el read model OURole usa role_id como PK.
  @roles [
    %{
      ou_id: "aurora.ong.direccion",
      role_id: "aurora.ong.direccion.director_general",
      role_name: "Director general",
      # Definición complementaria: el rol está asignado en la sistematización,
      # pero no aparece descrito en la hoja Roles.
      role_description:
        "Facilitar la coordinación general, representar la dirección y dar seguimiento al cumplimiento de los objetivos de Aurora."
    },
    %{
      ou_id: "aurora.ong.direccion",
      role_id: "aurora.ong.direccion.asistente_de_direccion",
      role_name: "Asistente de dirección",
      role_description:
        "Apoyar la coordinación, gestión documental y seguimiento de acuerdos y actividades."
    },
    %{
      ou_id: "aurora.ong.direccion",
      role_id: "aurora.ong.direccion.asistente_de_gestion_de_proyectos",
      role_name: "Asistente de Gestión de Proyectos",
      role_description:
        "Apoyar la planificación, documentación, seguimiento y coordinación de los proyectos."
    },
    %{
      ou_id: "aurora.ong.comunicaciones",
      role_id: "aurora.ong.comunicaciones.content_creator",
      role_name: "Content Creator",
      role_description:
        "Crear contenidos informativos y educativos alineados con la identidad y los objetivos de Aurora."
    },
    %{
      ou_id: "aurora.ong.comunicaciones",
      role_id: "aurora.ong.comunicaciones.community_manager",
      role_name: "Community Manager",
      role_description:
        "Gestionar las redes y la comunidad digital, planificar publicaciones, interactuar con las audiencias y monitorear métricas para fortalecer la participación."
    },
    %{
      ou_id: "aurora.ong.comunicaciones",
      role_id: "aurora.ong.comunicaciones.agente_de_difusion",
      role_name: "Agente de difusión",
      role_description:
        "Difundir actividades, convocatorias y contenidos de Aurora mediante canales estratégicos para ampliar su alcance y vinculación con nuevas comunidades."
    },
    %{
      ou_id: "aurora.ong.tecnologia",
      role_id: "aurora.ong.tecnologia.product_owner",
      role_name: "Product Owner",
      role_description:
        "Definir y priorizar el producto, ordenar necesidades del equipo y usuarios, y asegurar que el desarrollo tecnológico entregue valor alineado con los objetivos de Aurora."
    },
    %{
      ou_id: "aurora.ong.tecnologia",
      role_id: "aurora.ong.tecnologia.customer_success_engineer",
      role_name: "Customer Success Engineer",
      role_description:
        "Acompañar a los usuarios, resuelve necesidades y recopila retroalimentación para mejorar la plataforma."
    },
    %{
      ou_id: "aurora.ong.tecnologia",
      role_id: "aurora.ong.tecnologia.ingeniero_en_infraestructura_ti",
      role_name: "Ingeniero en infraestructura TI",
      role_description:
        "Mantener una infraestructura tecnológica segura, estable, disponible y trazable."
    },
    %{
      ou_id: "aurora.ong.tecnologia",
      role_id: "aurora.ong.tecnologia.ingeniero_qa",
      role_name: "Ingeniero QA",
      role_description:
        "Probar la plataforma, detectar errores y verificar el cumplimiento de los requisitos de calidad."
    },
    %{
      ou_id: "aurora.ong.tecnologia",
      role_id: "aurora.ong.tecnologia.product_analyst",
      role_name: "Product Analyst",
      role_description:
        "Analizar necesidades, métricas y comentarios de usuarios para proponer mejoras al producto."
    },
    %{
      ou_id: "aurora.ong.tecnologia",
      role_id: "aurora.ong.tecnologia.tech_lead",
      role_name: "Tech Lead",
      role_description:
        "Liderar el desarrollo técnico, orientar al equipo, definir estándares y asegurar soluciones seguras, escalables y alineadas con los objetivos del producto."
    },
    %{
      ou_id: "aurora.ong.tecnologia",
      role_id: "aurora.ong.tecnologia.desarrollador_frontend",
      role_name: "Desarrollador Frontend",
      # Definición complementaria por ausencia en la hoja Roles.
      role_description:
        "Desarrollar y mantener interfaces de usuario accesibles, responsivas y alineadas con los estándares del producto."
    },
    %{
      ou_id: "aurora.ong.financiamiento",
      role_id: "aurora.ong.financiamiento.gestor_de_financiamiento",
      role_name: "Gestor de financiamiento",
      role_description:
        "Identifica fondos, prepara postulaciones y realiza seguimiento a las oportunidades de financiamiento."
    }
  ]

  @role_assignments [
    {"aurora.ong.direccion.director_general", "aurora.ong.direccion", "p.delgado@aurora.ong"},
    {"aurora.ong.tecnologia.product_owner", "aurora.ong.tecnologia", "p.delgado@aurora.ong"},
    {"aurora.ong.direccion.asistente_de_direccion", "aurora.ong.direccion", "u.pinacho@aurora.ong"},
    {"aurora.ong.direccion.asistente_de_direccion", "aurora.ong.direccion", "f.carmona@aurora.ong"},
    {"aurora.ong.comunicaciones.content_creator", "aurora.ong.comunicaciones", "f.vega@aurora.ong"},
    {"aurora.ong.comunicaciones.community_manager", "aurora.ong.comunicaciones", "l.rodriguez@aurora.ong"},
    {"aurora.ong.comunicaciones.agente_de_difusion", "aurora.ong.comunicaciones", "m.ros@aurora.ong"},
    {"aurora.ong.comunicaciones.content_creator", "aurora.ong.comunicaciones", "a.castano@aurora.ong"},
    {"aurora.ong.tecnologia.ingeniero_qa", "aurora.ong.tecnologia", "a.fuentes@aurora.ong"},
    {"aurora.ong.tecnologia.tech_lead", "aurora.ong.tecnologia", "m.rosales@aurora.ong"},
    {"aurora.ong.tecnologia.desarrollador_frontend", "aurora.ong.tecnologia", "i.rojas@aurora.ong"},
    {"aurora.ong.financiamiento.gestor_de_financiamiento", "aurora.ong.financiamiento", "l.cuenca@aurora.ong"}
  ]

  @expected_counts %{
    ous: 6,
    people: 15,
    memberships: 42,
    roles: 14,
    role_assignments: 12
  }

  def run do
    password = System.fetch_env!("AURORA_BETA_DEFAULT_PASSWORD")

    Logger.info("[AuroraBetaSeed] Iniciando carga de datos BETA")

    create_ous!()
    register_people!(password)
    create_memberships!()
    promote_memberships_for_beta!()
    create_roles!()
    assign_roles!()
    verify!()

    Logger.info("[AuroraBetaSeed] Seed completado y verificado")
    :ok
  end

  def expected_counts, do: @expected_counts

  defp create_ous! do
    Enum.each(@ous, fn attrs ->
      dispatch!(struct!(CreateOU, attrs))
    end)
  end

  defp register_people!(password) do
    Enum.each(@people, fn %{person_id: person_id, person_name: person_name} ->
      attrs = %{
        person_id: person_id,
        person_name: person_name,
        person_mail: person_id,
        person_password: password
      }

      case PersonContext.register_person!(attrs) do
        {:ok, ^person_id} -> :ok
        {:error, changeset} -> raise "No se pudo registrar #{person_id}: #{inspect(changeset.errors)}"
      end
    end)
  end

  defp create_memberships! do
    Enum.each(@memberships, fn {ou_id, person_id} ->
      dispatch!(%StartMembership{ou_id: ou_id, person_id: person_id})
    end)
  end

  # Regla de preparación BETA:
  #
  # 1. StartMembership crea todas las membresías como junior.
  # 2. Promovemos una vez TODAS las membresías: junior -> regular.
  # 3. Las personas que ya eran "Miembro" en el registro fuente reciben
  #    una segunda promoción: regular -> senior.
  #
  # De esta manera todos los participantes pueden proponer y votar, pero
  # conservamos la diferencia relativa de rango que traía la fuente.
  defp promote_memberships_for_beta! do
    @memberships
    |> Enum.each(fn {ou_id, person_id} ->
      dispatch!(%PromoteMembership{ou_id: ou_id, person_id: person_id})
    end)

    @people
    |> Enum.filter(&(&1.quality == :member))
    |> Enum.map(& &1.person_id)
    |> MapSet.new()
    |> promote_people_in_all_memberships!()
  end

  defp promote_people_in_all_memberships!(person_ids) do
    @memberships
    |> Enum.filter(fn {_ou_id, person_id} -> MapSet.member?(person_ids, person_id) end)
    |> Enum.each(fn {ou_id, person_id} ->
      dispatch!(%PromoteMembership{ou_id: ou_id, person_id: person_id})
    end)
  end

  defp create_roles! do
    Enum.each(@roles, fn attrs ->
      dispatch!(struct!(CreateRole, attrs))
    end)
  end

  defp assign_roles! do
    Enum.each(@role_assignments, fn {role_id, ou_id, person_id} ->
      dispatch!(%AssignRole{role_id: role_id, ou_id: ou_id, person_id: person_id})
    end)
  end

  defp dispatch!(command) do
    case AuroraGov.dispatch(command, consistency: :strong) do
      :ok ->
        :ok

      {:ok, _result} ->
        :ok

      {:error, reason} ->
        raise "Falló #{inspect(command.__struct__)}: #{inspect(reason)}. Comando: #{inspect(command)}"

      other ->
        raise "Respuesta inesperada al ejecutar #{inspect(command.__struct__)}: #{inspect(other)}"
    end
  end

  defp verify! do
    actual = %{
      ous: Repo.aggregate(OU, :count, :ou_id),
      people: Repo.aggregate(Person, :count, :person_id),
      memberships: Repo.aggregate(Membership, :count, :person_id),
      roles: Repo.aggregate(OURole, :count, :role_id),
      role_assignments: Repo.aggregate(OURoleAssignment, :count, :person_id)
    }

    if actual != @expected_counts do
      raise "Verificación de seed fallida. Esperado=#{inspect(@expected_counts)} actual=#{inspect(actual)}"
    end

    malformed_ou_count =
      from(ou in OU,
        where: like(ou.ou_id, "%,%") or like(ou.ou_id, "% %") or like(ou.ou_id, "%dirección%"),
        select: count(ou.ou_id)
      )
      |> Repo.one()

    if malformed_ou_count != 0 do
      raise "Se detectaron #{malformed_ou_count} OU con identificadores no normalizados"
    end

    rank_counts = %{
      junior:
        from(m in Membership, where: m.membership_rank == :junior)
        |> Repo.aggregate(:count, :person_id),
      regular:
        from(m in Membership, where: m.membership_rank == :regular)
        |> Repo.aggregate(:count, :person_id),
      senior:
        from(m in Membership, where: m.membership_rank == :senior)
        |> Repo.aggregate(:count, :person_id)
    }

    expected_rank_counts = %{junior: 0, regular: 34, senior: 8}

    if rank_counts != expected_rank_counts do
      raise "Verificación de rangos BETA fallida. Esperado=#{inspect(expected_rank_counts)} actual=#{inspect(rank_counts)}"
    end

    :ok
  end
end

AuroraGov.Seeds.AuroraBeta.run()
