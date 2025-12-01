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
  power_id: "org.member.add",
  power_value: 100
})

AuroraGov.dispatch(%AuroraGov.Command.PromoteMembership{
  ou_id: "barrio_vivo.seguridad",
  person_id: "222@test.com"
})


# AuroraGov.dispatch(%AuroraGov.Command.UpdatePower{ou_id: "barrio_vivo", membership_id: "g4AFfCqpWtioetCuMbQJtu", power_id: "org.member.add", power_value: 100})
# AuroraGov.dispatch(%AuroraGov.Command.UpdatePower{ou_id: "barrio_vivo", membership_id: "g4AFfCqpWtioetCuMbQJtu", power_id: "org.member.add", power_value: 100})

proposal_params = %{
  proposal_title: "Propuesta de prueba",
  proposal_description: "Se solicita actualizar cierto poder..",
  proposal_ou_origin: "barrio_vivo.seguridad",
  proposal_person_id: "222@test.com",
  proposal_ou_end: "barrio_vivo.seguridad",
  proposal_power_id: "org.create",
  proposal_power_data: %{
    ou_id: "nuevo"
  }
}

AuroraGov.Context.ProposalContext.create_proposal(proposal_params)

proposal_params = %{
  proposal_title: "Propuesta de prueba 2",
  proposal_description: "Se solicita actualizar cierto poder..",
  proposal_ou_origin: "barrio_vivo.cultura_participacion",
  proposal_person_id: "000@test.com",
  proposal_ou_end: "barrio_vivo",
  proposal_power_id: "org.create",
  proposal_power_data: %{
    ou_id: "nuevo"
  }
}

AuroraGov.Context.ProposalContext.create_proposal(proposal_params)

proposal_params = %{
  proposal_title: "Propuesta de prueba 2",
  proposal_description: "Se solicita actualizar cierto poder..",
  proposal_ou_origin: "barrio_vivo",
  proposal_person_id: "000@test.com",
  proposal_ou_end: "barrio_vivo.cultura_participacion",
  proposal_power_id: "org.create",
  proposal_power_data: %{
    ou_id: "nuevo"
  }
}

AuroraGov.Context.ProposalContext.create_proposal(proposal_params)

# AuroraGov.dispatch(proposal)

AuroraGov.Aggregate.OU.get_ou("barrio_vivo.cultura_participacion")

vote_params = %{
  proposal_id: "a82b8be9-db44-48e8-bd50-c8a059deeb8f",
  person_id: "000@test.com",
  vote_value: 1,
  vote_comment: "Hola mundo",
  vote_type: "direct"
}
