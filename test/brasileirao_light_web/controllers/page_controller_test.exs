defmodule BrasileiraoLightWeb.PageControllerTest do
  use BrasileiraoLightWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Brasileirão 2025"
  end
end
