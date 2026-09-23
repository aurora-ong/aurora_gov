defmodule AuroraGov.Web.Test.ErrorJSONTest do
  use AuroraGov.Web.Test.ConnCase, async: false

  test "renders 404" do
    assert AuroraGov.Web.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert AuroraGov.Web.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
