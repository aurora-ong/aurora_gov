defmodule AuroraGov.Web.ToastHelper do
  def put_toast(socket, kind, msg, title \\ nil, icon \\ nil) do
    Phoenix.LiveView.push_event(socket, "toast", %{kind: to_string(kind), msg: msg, title: title, icon: icon})
  end
end
