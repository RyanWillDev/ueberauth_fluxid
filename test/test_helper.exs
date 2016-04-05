defmodule SpecRouter do
  use Plug.Router

  plug :fetch_query_params

  plug Ueberauth, base_path: "/auth"

  plug :match
  plug :dispatch

  get "/auth/flux" do
    send_resp(conn, 200, "FluxID request")
  end

  get "/auth/flux/callback" do
    send_resp(conn, 200, "FluxID callback")
  end
end

ExUnit.start()
