# **AuroraGov**

Digital Governance Platform based on Collective Intelligence.

More info https://aurora.ong

To contribute in this projects contact with Pavel Delgado (p.delgado@aurora.ong)

## Requeriments

* Docker
* Elixir

## Instructions

1. Run `mix deps.get`
2. Run Docker DB `docker run --env=POSTGRES_PASSWORD=aurora_gov -p 4500:5432 --name=aurora-gov -d postgres:latest`
3. Check config `config/config.exs`
4. Inicializate DB `mix setup`
5. Start app with `iex -S mix phx.server`
6. Visit [`localhost:4000`](http://localhost:4000) to access to web app

## Test Data

### Register Person

`%AuroraGov.Projector.Model.Person{} = AuroraGov.Context.PersonContext.register_person!(%{person_name: "Camila Saez", person_mail: "c.saez@gmail.com"})`

`%AuroraGov.Projector.Model.Person{} = AuroraGov.Context.PersonContext.register_person!(%{person_name: "Pedro Diaz", person_mail: "p.diaz@gmail.com"})`

### Register Organizational Unit

`:ok = AuroraGov.dispatch(%AuroraGov.Command.CreateOU{ou_id: "raiz", ou_name: "Raiz ORG", ou_description: "Creada para enraizar", ou_goal: "Fomentar la cultura de raíz"})`

`:ok = AuroraGov.dispatch(%AuroraGov.Command.CreateOU{ou_id: "raiz.sub", ou_name: "SUB Departamento finanzas", ou_description: "Creada para financiar", ou_goal: "Financiar la organización"})`

### Register Membership

`:ok = AuroraGov.dispatch(%AuroraGov.Command.StartMembership{ou_id: "raiz", person_id: "111"})`

`:ok = AuroraGov.dispatch(%AuroraGov.Command.StartMembership{ou_id: "raiz", person_id: "333"})`
`:ok = AuroraGov.dispatch(%AuroraGov.Command.StartMembership{ou_id: "raiz.sub", person_id: "333"})`

