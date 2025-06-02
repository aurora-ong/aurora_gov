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







