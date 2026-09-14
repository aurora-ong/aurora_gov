# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     AuroraGov.Projector.Repo.insert!(%AuroraGov.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

AuroraGov.dispatch(%AuroraGov.Command.CreateOU{
  ou_id: "barrio_vivo",
  ou_name: "Red de Barrios Vivos",
  ou_description:
    "La Red de Barrios Vivos es una organización ciudadana que reúne a distintas juntas de vecinos y colectivos territoriales bajo una estructura descentralizada y democrática. Su propósito es conectar a comunidades locales para resolver problemáticas comunes, como la seguridad, el acceso a áreas verdes, la cultura comunitaria y la gestión de recursos.",
  ou_goal:
    "Fortalecer la organización comunitaria entre barrios para impulsar iniciativas colaborativas de mejora urbana, apoyo mutuo y sostenibilidad local."
})

AuroraGov.dispatch(%AuroraGov.Command.CreateOU{
  ou_id: "barrio_vivo.espacios_publicos",
  ou_name: "Comisión de Espacios Públicos",
  ou_description:
    "Promueve la recuperación y diseño colaborativo de plazas, parques y áreas comunes.",
  ou_goal:
    "Fomentar espacios públicos inclusivos, seguros y bien cuidados mediante participación comunitaria."
})

AuroraGov.dispatch(%AuroraGov.Command.CreateOU{
  ou_id: "barrio_vivo.seguridad",
  ou_name: "Comisión de Seguridad Comunitaria",
  ou_description:
    "Coordina acciones vecinales para prevenir delitos y fortalecer la confianza entre vecinos.",
  ou_goal:
    "Mejorar la seguridad barrial a través de vigilancia colaborativa, redes de apoyo y protocolos de acción conjunta."
})

AuroraGov.dispatch(%AuroraGov.Command.CreateOU{
  ou_id: "barrio_vivo.cultura_participacion",
  ou_name: "Comisión de Cultura y Participación",
  ou_description:
    "Organiza eventos, talleres y espacios de encuentro para fortalecer la identidad barrial.",
  ou_goal:
    "Impulsar la vida cultural y el involucramiento activo de los vecinos en la construcción de comunidad."
})

AuroraGov.Context.PersonContext.register_person!(%{
  person_id: "000@test.com",
  person_name: "Camila Saez",
  person_mail: "c.saez@gmail.com",
  person_password: "123456"
})

AuroraGov.Context.PersonContext.register_person!(%{
  person_id: "111@test.com",
  person_name: "Pedro Diaz",
  person_mail: "c.saez@gmail.com",
  person_password: "123456"
})

AuroraGov.Context.PersonContext.register_person!(%{
  person_id: "222@test.com",
  person_name: "Sebastian Duran",
  person_mail: "c.saez@gmail.com",
  person_password: "123456"
})

AuroraGov.Context.PersonContext.register_person!(%{
  person_id: "333@test.com",
  person_name: "Maria Arevalo",
  person_mail: "c.saez@gmail.com",
  person_password: "123456"
})

AuroraGov.dispatch(%AuroraGov.Command.StartMembership{
  ou_id: "barrio_vivo",
  person_id: "000@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.StartMembership{
  ou_id: "barrio_vivo",
  person_id: "111@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.StartMembership{
  ou_id: "barrio_vivo",
  person_id: "222@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.StartMembership{
  ou_id: "barrio_vivo",
  person_id: "333@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.StartMembership{
  ou_id: "barrio_vivo.cultura_participacion",
  person_id: "000@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.StartMembership{
  ou_id: "barrio_vivo.cultura_participacion",
  person_id: "111@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.StartMembership{
  ou_id: "barrio_vivo.cultura_participacion",
  person_id: "222@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.StartMembership{
  ou_id: "barrio_vivo.seguridad",
  person_id: "222@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.StartMembership{
  ou_id: "barrio_vivo.seguridad",
  person_id: "333@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.PromoteMembership{
  ou_id: "barrio_vivo",
  person_id: "000@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.PromoteMembership{
  ou_id: "barrio_vivo",
  person_id: "000@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.PromoteMembership{
  ou_id: "barrio_vivo",
  person_id: "111@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.PromoteMembership{
  ou_id: "barrio_vivo",
  person_id: "111@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.PromoteMembership{
  ou_id: "barrio_vivo",
  person_id: "222@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.PromoteMembership{
  ou_id: "barrio_vivo",
  person_id: "333@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.PromoteMembership{
  ou_id: "barrio_vivo.seguridad",
  person_id: "000@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.PromoteMembership{
  ou_id: "barrio_vivo.cultura_participacion",
  person_id: "000@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.PromoteMembership{
  ou_id: "barrio_vivo.cultura_participacion",
  person_id: "111@test.com"
})

AuroraGov.dispatch(%AuroraGov.Command.UpdatePower{
  ou_id: "barrio_vivo",
  person_id: "000@test.com",
  power_id: "org.membership.start",
  power_value: 100
})

AuroraGov.dispatch(%AuroraGov.Command.PromoteMembership{
  ou_id: "barrio_vivo.seguridad",
  person_id: "222@test.com"
})

# AuroraGov.dispatch(%AuroraGov.Command.UpdatePower{ou_id: "barrio_vivo", membership_id: "g4AFfCqpWtioetCuMbQJtu", power_id: "org.member.add", power_value: 100})
# AuroraGov.dispatch(%AuroraGov.Command.UpdatePower{ou_id: "barrio_vivo", membership_id: "g4AFfCqpWtioetCuMbQJtu", power_id: "org.member.add", power_value: 100})

# proposal_params = %{
#   proposal_title: "Propuesta de prueba",
#   proposal_description: "Se solicita actualizar cierto poder..",
#   proposal_ou_origin: "barrio_vivo.seguridad",
#   proposal_person_id: "222@test.com",
#   proposal_ou_end: "barrio_vivo.seguridad",
#   proposal_power_id: "org.create",
#   proposal_power_data: %{
#     ou_id: "nuevo"
#   }
# }

# AuroraGov.Context.ProposalContext.create_proposal(proposal_params)

# proposal_params = %{
#   proposal_title: "Propuesta de prueba 2",
#   proposal_description: "Se solicita actualizar cierto poder..",
#   proposal_ou_origin: "barrio_vivo.cultura_participacion",
#   proposal_person_id: "000@test.com",
#   proposal_ou_end: "barrio_vivo",
#   proposal_power_id: "org.create",
#   proposal_power_data: %{
#     ou_id: "nuevo"
#   }
# }

# AuroraGov.Context.ProposalContext.create_proposal(proposal_params)

proposal_params = %{
  proposal_title: "Nueva OU",
  proposal_description: "Se solicita crear nuevo departamento..",
  proposal_ou_origin: "barrio_vivo",
  proposal_person_id: "000@test.com",
  proposal_ou_end: "barrio_vivo.cultura_participacion",
  proposal_power_id: "org.ou.create",
  proposal_power_data: %{
    ou_id: "barrio_vivo.d",
    ou_name: "Nuevo OU",
    ou_goal: "Objetivo de la unidad",
    ou_description: "Descripción de la unidad"
  }
}

AuroraGov.Context.ProposalContext.create_proposal!(proposal_params)

# # AuroraGov.dispatch(proposal)

# AuroraGov.Aggregate.OU.get_ou("barrio_vivo.cultura_participacion")

# vote_params = %{
#   proposal_id: "a82b8be9-db44-48e8-bd50-c8a059deeb8f",
#   person_id: "000@test.com",
#   vote_value: 1,
#   vote_comment: "Hola mundo",
#   vote_type: "direct"
# }

# AuroraGov.Context.ProposalContext.consume_proposal!("1ea9bccf-1dd5-4d73-8242-3f7f496a11a0")

# --- Datos de Prueba para la Capa Operativa (V2) ---

# 1. Crear Proyecto
AuroraGov.dispatch(%AuroraGov.Command.CreateProject{
  ou_id: "barrio_vivo",
  project_id: "huerto_urbano",
  name: "Huerto Urbano Comunitario",
  description: "Construcción y mantención de un huerto urbano cooperativo en la plaza central."
})

# 3. Crear Tareas
AuroraGov.dispatch(%AuroraGov.Command.CreateTask{
  ou_id: "barrio_vivo",
  project_id: "huerto_urbano",
  task_id: "armar_madera",
  name: "Ensamblar estructuras de madera",
  description: "Armar las cajas de madera y forrarlas por dentro.",
  goal: "Tener 10 estructuras armadas"
})

# Asignar Tareas
AuroraGov.dispatch(%AuroraGov.Command.AssignTask{
  ou_id: "barrio_vivo",
  project_id: "huerto_urbano",
  task_id: "armar_madera",
  person_id: "111@test.com",
  estimated_delivery_at: DateTime.add(DateTime.utc_now(), 7, :day)
})

AuroraGov.dispatch(%AuroraGov.Command.CreateTask{
  ou_id: "barrio_vivo",
  project_id: "huerto_urbano",
  task_id: "tender_tuberias",
  name: "Instalación de cañerías y goteros",
  description: "Conectar mangueras al grifo central y posicionar los goteros.",
  goal: "Tener 100 metros de tuberías tendidas"
})

AuroraGov.dispatch(%AuroraGov.Command.AssignTask{
  ou_id: "barrio_vivo",
  project_id: "huerto_urbano",
  task_id: "tender_tuberias",
  person_id: "222@test.com",
  estimated_delivery_at: DateTime.add(DateTime.utc_now(), 3, :day)
})

# Tarea Completada
AuroraGov.dispatch(%AuroraGov.Command.CreateTask{
  ou_id: "barrio_vivo",
  project_id: "huerto_urbano",
  task_id: "comprar_semillas",
  name: "Comprar semillas de temporada",
  description: "Adquirir semillas de hortalizas aptas para la temporada de otoño/invierno.",
  goal: "Tener el stock inicial de semillas"
})

AuroraGov.dispatch(%AuroraGov.Command.AssignTask{
  ou_id: "barrio_vivo",
  project_id: "huerto_urbano",
  task_id: "comprar_semillas",
  person_id: "333@test.com",
  estimated_delivery_at: DateTime.add(DateTime.utc_now(), 1, :day)
})

AuroraGov.dispatch(%AuroraGov.Command.CompleteTask{
  ou_id: "barrio_vivo",
  project_id: "huerto_urbano",
  task_id: "comprar_semillas"
})

# Tarea Completada y Evaluada
AuroraGov.dispatch(%AuroraGov.Command.CreateTask{
  ou_id: "barrio_vivo",
  project_id: "huerto_urbano",
  task_id: "diseno_plano",
  name: "Diseñar plano del huerto",
  description: "Realizar el levantamiento topográfico y diseñar dónde irá cada cultivo.",
  goal: "Tener un plano base aprobado"
})

AuroraGov.dispatch(%AuroraGov.Command.AssignTask{
  ou_id: "barrio_vivo",
  project_id: "huerto_urbano",
  task_id: "diseno_plano",
  person_id: "111@test.com",
  estimated_delivery_at: DateTime.add(DateTime.utc_now(), 2, :day)
})

AuroraGov.dispatch(%AuroraGov.Command.CompleteTask{
  ou_id: "barrio_vivo",
  project_id: "huerto_urbano",
  task_id: "diseno_plano"
})

AuroraGov.dispatch(%AuroraGov.Command.EvaluateTask{
  ou_id: "barrio_vivo",
  project_id: "huerto_urbano",
  task_id: "diseno_plano",
  review: "Excelente trabajo, el plano consideró los senderos accesibles que solicitamos.",
  score: 95
})

# Tarea Abandonada
AuroraGov.dispatch(%AuroraGov.Command.CreateTask{
  ou_id: "barrio_vivo",
  project_id: "huerto_urbano",
  task_id: "limpiar_terreno",
  name: "Limpieza profunda del terreno",
  description: "Retirar escombros y basura acumulada en el sector nororiente de la plaza.",
  goal: "Terreno despejado y apto para sembrar"
})

AuroraGov.dispatch(%AuroraGov.Command.AssignTask{
  ou_id: "barrio_vivo",
  project_id: "huerto_urbano",
  task_id: "limpiar_terreno",
  person_id: "222@test.com",
  estimated_delivery_at: DateTime.add(DateTime.utc_now(), 4, :day)
})

AuroraGov.dispatch(%AuroraGov.Command.AbandonTask{
  ou_id: "barrio_vivo",
  project_id: "huerto_urbano",
  task_id: "limpiar_terreno"
})

# --- Datos de Prueba para la Capa Económica (Ledger) ---

# 1. Crear Recursos
AuroraGov.dispatch(%AuroraGov.Command.CreateResource{
  resource_id: "clp",
  name: "Pesos Chilenos",
  description: "Moneda fiduciaria de curso legal para donaciones e ingresos externos.",
  is_fungible: true,
  unit_of_measure: "CLP$",
  ou_id: "barrio_vivo"
})

AuroraGov.dispatch(%AuroraGov.Command.CreateResource{
  resource_id: "hh_barrio",
  name: "Horas de Trabajo Solidario",
  description: "Medida representativa del esfuerzo aportado voluntariamente por los miembros de la comunidad para proyectos compartidos.",
  is_fungible: true,
  unit_of_measure: "HH",
  ou_id: "barrio_vivo"
})

AuroraGov.dispatch(%AuroraGov.Command.CreateResource{
  resource_id: "arboles",
  name: "Árboles Nativos",
  description: "Unidad contable para medir la cantidad de árboles donados y listos para plantación comunitaria.",
  is_fungible: true,
  unit_of_measure: "Árbol",
  ou_id: "barrio_vivo.espacios_publicos"
})

AuroraGov.dispatch(%AuroraGov.Command.CreateResource{
  resource_id: "hh_patrullaje",
  name: "Horas de Patrullaje",
  description: "Horas de trabajo invertidas por vecinos voluntarios en las rondas nocturnas de vigilancia.",
  is_fungible: true,
  unit_of_measure: "HH",
  ou_id: "barrio_vivo.seguridad"
})

# 2. Crear Cuentas
AuroraGov.dispatch(AuroraGov.Command.CreateLedger.new(%{
  "ledger_id" => "1111111111",
  "owner_id" => "barrio_vivo",
  "ledger_type" => "asset",
  "resource_id" => "clp",
  "name" => "Caja General",
  "description" => "Fondos centrales de la Red"
}) |> Ecto.Changeset.apply_action!(:insert))

AuroraGov.dispatch(AuroraGov.Command.CreateLedger.new(%{
  "ledger_id" => "2222222222",
  "owner_id" => "barrio_vivo",
  "ledger_type" => "asset",
  "resource_id" => "hh_barrio",
  "name" => "Banco de Tiempo Barrial",
  "description" => "Bolsa de horas de trabajo aportadas"
}) |> Ecto.Changeset.apply_action!(:insert))

AuroraGov.dispatch(AuroraGov.Command.CreateLedger.new(%{
  "ledger_id" => "3333333333",
  "owner_id" => "barrio_vivo.cultura_participacion",
  "ledger_type" => "asset",
  "resource_id" => "clp",
  "name" => "Fondo de Cultura",
  "description" => "Fondos para eventos culturales"
}) |> Ecto.Changeset.apply_action!(:insert))

AuroraGov.dispatch(AuroraGov.Command.CreateLedger.new(%{
  "ledger_id" => "5555555555",
  "owner_id" => "barrio_vivo.espacios_publicos",
  "ledger_type" => "asset",
  "resource_id" => "clp",
  "name" => "Presupuesto Plazas",
  "description" => "Dinero destinado a la reparación de plazas"
}) |> Ecto.Changeset.apply_action!(:insert))

AuroraGov.dispatch(AuroraGov.Command.CreateLedger.new(%{
  "ledger_id" => "4444444444",
  "owner_id" => "barrio_vivo",
  "ledger_type" => "external",
  "resource_id" => "clp",
  "name" => "Donantes Anónimos",
  "description" => "Cuenta puente para donaciones"
}) |> Ecto.Changeset.apply_action!(:insert))

# 3. Transacciones (Movimientos)
AuroraGov.dispatch(AuroraGov.Command.RecordTransaction.new(%{
  "reference_id" => "DONACION-INICIAL",
  "origin_ledger_id" => "4444444444",
  "destination_ledger_id" => "1111111111",
  "amount" => "1500000",
  "description" => "Donación inicial de vecinos para conformar la caja"
}) |> Ecto.Changeset.apply_action!(:insert))

AuroraGov.dispatch(AuroraGov.Command.RecordTransaction.new(%{
  "reference_id" => "ASIG-FONDO-CULT",
  "origin_ledger_id" => "1111111111",
  "destination_ledger_id" => "3333333333",
  "amount" => "500000",
  "description" => "Traspaso de presupuesto para cultura"
}) |> Ecto.Changeset.apply_action!(:insert))
  AuroraGov.dispatch(AuroraGov.Command.CreateLedger.new(%{
    "ledger_id" => "8888888888",
    "owner_id" => "barrio_vivo.espacios_publicos",
    "ledger_type" => "asset",
    "resource_id" => "arboles",
    "name" => "Vivero Comunitario",
    "description" => "Stock de árboles en espera de ser trasplantados a las plazas del barrio."
  }) |> Ecto.Changeset.apply_action!(:insert))

  AuroraGov.dispatch(AuroraGov.Command.CreateLedger.new(%{
    "ledger_id" => "9999999999",
    "owner_id" => "barrio_vivo.seguridad",
    "ledger_type" => "asset",
    "resource_id" => "hh_patrullaje",
    "name" => "Bolsa de Rondas Nocturnas",
    "description" => "Registro general del tiempo aportado por los vigilantes de cuadra."
  }) |> Ecto.Changeset.apply_action!(:insert))
