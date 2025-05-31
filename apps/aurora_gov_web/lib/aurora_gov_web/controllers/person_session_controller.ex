defmodule AuroraGovWeb.PersonSessionController do
  use AuroraGovWeb, :controller

  alias AuroraGov.Context.PersonContext
  alias AuroraGovWeb.Auth

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(conn, %{"person" => person_params}, info) do
    %{"id" => id, "password" => password} = person_params

    if person = PersonContext.get_person_by_id_and_password(id, password) do
      conn
      |> put_flash(:info, info)
      |> Auth.log_in_person(person, person_params)
    else
      # In order to prevent user enumeration attacks, don't disclose whether the email is registered.
      conn
      |> put_flash(:error, "Invalid id or password")
      |> redirect(to: ~p"/persons/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> Auth.log_out_person()
  end
end
