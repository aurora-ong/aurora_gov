# **AuroraGov**

Digital Governance Platform based on Collective Intelligence.

More info https://aurora.ong

To contribute in this projects contact with Pavel Delgado (p.delgado@aurora.ong)

## ⚖️ License

AuroraGov is distributed under the **Elastic License 2.0 (ELv2)**.

This is a **Source Available** model that guarantees:

* ✅ **Freedom of Use:** You can download, modify, and run AuroraGov for your own organization (self-hosting) completely free of charge.
* ✅ **Transparency:** The code is 100% auditable and open.
* ❌ **Commercial Protection:** You are not allowed to offer AuroraGov as a managed service (SaaS) to third parties. In other words, you cannot commercially sell "AuroraGov Hosting" without a prior agreement with us.

For commercial licenses or Enterprise use, please contact us at: contacto@aurora.ong

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


## Test Commands

### Registrar persona

`{:ok, person} = AuroraGov.Context.PersonContext.register_person!(%{person_name: "Camila Saez", person_id: "c.saez@gmail.com", person_mail: "c.saez@gmail.com", person_password: "123456"})`

### Iniciar membresía
`{:ok, membership} = AuroraGov.dispatch(%AuroraGov.Command.StartMembership{ou_id: "barrio_vivo", person_id: "c.saez@gmail.com"})`


