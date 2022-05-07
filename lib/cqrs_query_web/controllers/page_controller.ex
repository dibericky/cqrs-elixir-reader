alias CqrsQuery.Repo

defmodule CqrsQueryWeb.PageController do
  use CqrsQueryWeb, :controller

  def index(conn, _params) do
    data = CqrsQuery.get_events("abc")
    product = CqrsQuery.get_product("abc")
    render(conn, "index.html", events: data, product: product)
  end
end
