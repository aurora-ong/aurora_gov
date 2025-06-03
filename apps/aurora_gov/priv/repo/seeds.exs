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
