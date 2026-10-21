defmodule AuroraGov.Web.Live.BetaTestLive do
  use AuroraGov.Web, :live_view

  @slides [
    %{
      type: :intro,
      section: "ONBOARDING",
      title: "Bienvenidos a AuroraGov",
      subtitle: "Conocer. Participar. Decidir.",
      chips: ["Gobernanza", "Participación", "Transparencia"]
    },
    %{
      type: :objective,
      section: "OBJETIVO",
      title: "¿Qué vamos a probar?",
      subtitle: "Una experiencia real de gobernanza digital.",
      cards: [
        {"Conocer", "Interfaz y estructura"},
        {"Participar", "Propuestas y decisiones"},
        {"Evaluar", "Usabilidad y funcionamiento"}
      ]
    },
    %{
      type: :principles,
      section: "ORGANIZACIÓN A",
      title: "Principios de Organización A",
      subtitle: "Una organización distribuida, transparente y adaptable.",
      principles: [
        {"Descentralizada", "Poder distribuido"},
        {"Representativa", "Participación"},
        {"Transparente", "Información abierta"},
        {"Modular", "Unidades autónomas"},
        {"Sostenible", "Impacto responsable"},
        {"Adaptativa", "Evolución"},
        {"Equitativa", "Reglas justas"},
        {"Razonable", "Evidencia"}
      ]
    },
    %{
      type: :screen,
      section: "ACCESO",
      title: "Inicio de sesión",
      subtitle: "Cada integrante utiliza su cuenta oficial de Aurora.",
      image: "/images/beta/01-inicio-sesion.png",
      chips: ["Email @aurora.ong", "Password BETA", "Cuenta existente"],
      highlight: "Durante la BETA no es necesario registrarse."
    },
    %{
      type: :screen,
      section: "AURORAGOV",
      title: "Panel principal",
      subtitle: "La organización y sus herramientas en un mismo lugar.",
      image: "/images/beta/02-panel-principal-beta.png",
      chips: ["Aurora", "Gobernar", "Navegar", "Actividad"],
      highlight:
        "Para esta prueba los integrantes utilizarán membresías Regular y Senior, niveles habilitados para participar en la toma de decisiones."
    },
    %{
      type: :screen,
      section: "TRANSPARENCIA",
      title: "Actividad",
      subtitle: "Las acciones de la organización quedan visibles y registradas.",
      image: "/images/beta/03-actividad-organizacion.png",
      chips: ["Actividad", "Historial", "ID único", "Auditoría"],
      highlight:
        "Cada acción registrada puede identificarse y consultarse desde el historial de actividad."
    },
    %{
      type: :screen,
      section: "NAVEGACIÓN",
      title: "Menú lateral",
      subtitle: "Acceso a las principales funciones de AuroraGov.",
      image: "/images/beta/04-menu-lateral.png",
      chips: ["Miembros", "Roles", "Poder", "Propuestas", "Proyectos", "Recursos"]
    },
    %{
      type: :screen,
      section: "ORGANIZACIÓN",
      title: "Navegar unidades",
      subtitle: "Recorré la estructura de Aurora y sus unidades.",
      image: "/images/beta/05-navegar-unidades.png",
      chips: ["Aurora", "Aurora ONG", "Unidades", "Modularidad"],
      highlight:
        "Navegar permite cambiar el contexto organizacional sobre el que estamos trabajando."
    },
    %{
      type: :screen,
      section: "GOBERNANZA",
      title: "Gobernar",
      subtitle: "Elegí desde dónde actuar y dónde producir el cambio.",
      image: "/images/beta/06-gobernar-origen-destino.png",
      chips: ["Unidad origen", "Unidad destino", "Acción"],
      highlight:
        "Desde Gobernar se define la unidad de origen, la unidad de destino y la acción que se quiere proponer."
    },
    %{
      type: :screen,
      section: "GOBERNANZA",
      title: "Elegir una acción",
      subtitle: "Cada acción representa un poder de gobernanza.",
      image: "/images/beta/07-selector-acciones.png",
      chips: ["Membresía", "Unidad", "Roles", "Recursos"],
      highlight:
        "Cada acción puede abrir un formulario distinto. Durante la BETA iremos probando diferentes casos."
    },
    %{
      type: :screen,
      section: "PERSONAS",
      title: "Miembros",
      subtitle: "Quiénes forman parte de cada unidad.",
      image: "/images/beta/08-miembros.png",
      chips: ["Miembro", "Unidad", "Regular", "Senior"],
      highlight:
        "La membresía indica la relación entre una persona y una unidad organizacional."
    },
    %{
      type: :screen,
      section: "DECISIONES",
      title: "Propuestas",
      subtitle: "Las acciones pueden convertirse en decisiones colectivas.",
      image: "/images/beta/09-propuesta-testing.png",
      chips: ["Proponer", "Votar", "Testing", "Ejecutar"],
      highlight:
        "Durante la prueba utilizaremos casos concretos, como la creación del rol Testing."
    },
    %{
      type: :screen,
      section: "RESPONSABILIDADES",
      title: "Roles",
      subtitle: "Responsabilidades dentro de una unidad.",
      image: "/images/beta/10-roles-testing.png",
      chips: ["Rol", "Asignación", "Testing", "Responsabilidad"],
      highlight:
        "Una membresía indica pertenencia. Un rol indica una responsabilidad."
    },
    %{
  type: :screen,
  section: "RESPONSABILIDADES",
  title: "Roles",
  subtitle: "Responsabilidades dentro de una unidad.",
  image: "/images/beta/10-roles-testing.png",
  chips: ["Rol", "Asignación", "Testing", "Responsabilidad"],
  highlight:
    "Una membresía indica pertenencia. Un rol indica una responsabilidad."
},
%{
  type: :screen,
  section: "TRABAJO",
  title: "Proyectos",
  subtitle: "Iniciativas y esfuerzos de la organización.",
  image: "/images/beta/17-proyectos.png",
  chips: ["Proyecto", "Unidad", "Trabajo", "Objetivo"],
  highlight:
    "Los proyectos permiten organizar iniciativas y vincularlas con una unidad de Aurora."
},
%{
  type: :screen,
  section: "RECURSOS",
  title: "Recursos contables",
  subtitle: "Cuentas, recursos y operaciones de la organización.",
  image: "/images/beta/18-recursos-contables.png",
  chips: ["Cuentas", "Recursos", "Transacciones", "Transparencia"],
  highlight:
    "Los recursos contables permiten registrar y administrar recursos de manera transparente."
},
%{
  type: :screen,
  section: "PODER",
  title: "Poderes de gobernanza",
  subtitle: "Acciones capaces de modificar la organización.",
  image: "/images/beta/11-poderes.png",
  chips: ["Poder", "Acción", "Quórum", "Participación"],
  highlight:
    "Un poder no representa a una persona poderosa: representa una acción gobernable."
},
%{
  type: :screen,
  section: "DECISIÓN",
  title: "Quórum y postura",
  subtitle: "Cada poder puede requerir un nivel diferente de acuerdo.",
  image: "/images/beta/12-quorum-y-postura.png",
  chips: ["Quórum colectivo", "Mi postura", "Consenso"],
  highlight:
    "El criterio colectivo se construye a partir de las posturas definidas por los integrantes."
},
%{
  type: :postures,
  section: "POSTURAS",
  title: "Tres niveles de decisión",
  subtitle: "Cada integrante expresa qué nivel de acuerdo considera adecuado.",
  images: [
    %{
      image: "/images/beta/13-postura-agil.png",
      title: "Ágil",
      value: "0 a 34",
      description: "Menor exigencia. Decisiones más rápidas."
    },
    %{
      image: "/images/beta/14-postura-flexible.png",
      title: "Flexible",
      value: "34 a 75",
      description: "Equilibrio entre agilidad y consenso."
    },
    %{
      image: "/images/beta/15-postura-cautelosa.png",
      title: "Cautelosa",
      value: "76 a 100",
      description: "Mayor consenso para decidir."
    }
  ]
},
%{
  type: :screen,
  section: "DEMOCRACIA LÍQUIDA",
  title: "Delegar poder",
  subtitle: "Podés confiar tu capacidad de decisión a otra unidad.",
  image: "/images/beta/16-delegacion-poder.png",
  chips: ["Delegación", "Confianza", "Representación", "Revocable"],
  highlight:
    "La delegación permite construir una representación dinámica basada en confianza."
},
    %{
      type: :screen,
      section: "PODER",
      title: "Poderes de gobernanza",
      subtitle: "Acciones capaces de modificar la organización.",
      image: "/images/beta/11-poderes.png",
      chips: ["Poder", "Acción", "Quórum", "Participación"],
      highlight:
        "Un poder no representa a una persona poderosa: representa una acción gobernable."
    },
    %{
      type: :screen,
      section: "DECISIÓN",
      title: "Quórum y postura",
      subtitle: "Cada poder puede requerir un nivel diferente de acuerdo.",
      image: "/images/beta/12-quorum-y-postura.png",
      chips: ["Quórum colectivo", "Mi postura", "Consenso"],
      highlight:
        "El criterio colectivo se construye a partir de las posturas definidas por los integrantes."
    },
    %{
      type: :postures,
      section: "POSTURAS",
      title: "Tres niveles de decisión",
      subtitle: "Cada integrante expresa qué nivel de acuerdo considera adecuado.",
      images: [
        %{
          image: "/images/beta/13-postura-agil.png",
          title: "Ágil",
          value: "0 a 33",
          description: "Menor exigencia. Decisiones más rápidas."
        },
        %{
          image: "/images/beta/14-postura-flexible.png",
          title: "Flexible",
          value: "34 a 66",
          description: "Equilibrio entre agilidad y consenso."
        },
        %{
          image: "/images/beta/15-postura-cautelosa.png",
          title: "Cautelosa",
          value: "67 a 100",
          description: "Mayor consenso para decidir."
        }
      ]
    },
    %{
      type: :screen,
      section: "DEMOCRACIA LÍQUIDA",
      title: "Delegar poder",
      subtitle: "Podés confiar tu capacidad de decisión a otra unidad.",
      image: "/images/beta/16-delegacion-poder.png",
      chips: ["Delegación", "Confianza", "Representación", "Revocable"],
      highlight:
        "La delegación permite construir una representación dinámica basada en confianza."
    },
    %{
      type: :final,
      section: "COMENZAR",
      title: "Listos para la prueba BETA",
      subtitle: "Ahora comienza la experiencia práctica."
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Prueba BETA")
     |> assign(:slides, @slides)
     |> assign(:total_steps, length(@slides))
     |> assign_slide(0)}
  end

  @impl true
  def handle_event("next", _params, socket) do
    step =
      min(
        socket.assigns.step + 1,
        socket.assigns.total_steps - 1
      )

    {:noreply, assign_slide(socket, step)}
  end

  @impl true
  def handle_event("previous", _params, socket) do
    step = max(socket.assigns.step - 1, 0)

    {:noreply, assign_slide(socket, step)}
  end

  defp assign_slide(socket, step) do
    socket
    |> assign(:step, step)
    |> assign(:slide, Enum.at(@slides, step))
  end

  # ---------------------------------------------------------------------------
  # COMPONENTES VISUALES BETA
  # ---------------------------------------------------------------------------

  attr :step, :integer, required: true
  attr :total_steps, :integer, required: true

  def beta_progress(assigns) do
    ~H"""
    <div class="h-1 w-full bg-slate-100">
      <div
        class="h-full bg-orange-500 transition-all duration-300"
        style={"width: #{round((@step + 1) / @total_steps * 100)}%"}
      >
      </div>
    </div>
    """
  end

  attr :label, :string, required: true

  def beta_chip(assigns) do
    ~H"""
    <span class="
      inline-flex items-center
      rounded-full border border-slate-200
      bg-white px-3 py-1.5
      text-xs font-semibold text-slate-700
      shadow-sm
      sm:text-sm
    ">
      {@label}
    </span>
    """
  end

  attr :title, :string, required: true
  attr :description, :string, required: true

  def beta_principle(assigns) do
    ~H"""
    <article class="
      rounded-2xl border border-slate-200
      bg-white p-4 shadow-sm
      sm:p-5
    ">
      <h3 class="font-bold text-slate-900">
        {@title}
      </h3>

      <p class="mt-1 text-sm text-slate-500">
        {@description}
      </p>
    </article>
    """
  end

  attr :previous?, :boolean, required: true
  attr :next?, :boolean, required: true

  def beta_navigation(assigns) do
    ~H"""
    <div class="
      mx-auto mt-7 flex w-full max-w-7xl
      flex-col gap-3
      sm:mt-9 sm:flex-row
      sm:items-center sm:justify-between
    ">
      <%= if @previous? do %>
        <button
          type="button"
          phx-click="previous"
          class="
            inline-flex min-h-12 w-full
            items-center justify-center gap-2
            rounded-xl border border-slate-300
            bg-white px-5 py-3
            font-semibold text-slate-700
            transition hover:bg-slate-50
            sm:w-auto
          "
        >
          ← Anterior
        </button>
      <% else %>
        <div></div>
      <% end %>

      <%= if @next? do %>
        <button
          type="button"
          phx-click="next"
          class="
            inline-flex min-h-12 w-full
            items-center justify-center gap-2
            rounded-xl bg-orange-500
            px-5 py-3
            font-semibold text-white
            shadow-sm transition
            hover:bg-orange-600
            sm:w-auto
          "
        >
          Siguiente →
        </button>
      <% end %>
    </div>
    """
  end
end
