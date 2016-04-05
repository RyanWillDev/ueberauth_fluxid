# UeberauthFluxID

> FluxID OAuth2 strategy for Überauth.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

1. Add ueberauth_fluxid to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:ueberauth_fluxid, "~> 0.0.1"}]
  end
  ```

2. Ensure ueberauth_fluxid is started before your application:

  ```elixir
  def application do
    [applications: [:ueberauth_fluxid]]
  end
  ```

## Usage

1. Configure Überauth and FluxID OAuth.

  ```elixir
  config :ueberauth, Ueberauth,
    providers: [
      flux: {Ueberauth.Strategy.FluxID, []}
    ]

  config :ueberauth, Ueberauth.Strategy.FluxID.OAuth,
    client_id: System.get_env("FLUXID_CLIENT_ID"),
    client_secret: System.get_env("FLUXID_CLIENT_SECRET"),
    redirect_uri: System.get_env("FLUXID_REDIRECT_URI")
  ```

2. Create request and callback routes.

  ```elixir
  scope "/auth", App do
    pipe_through :browser

    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end
  ```

3. Handle request and callback phases.

  ```elixir
  defmodule Catalog.AuthController do
    use Catalog.Web, :controller

    alias Ueberauth.Strategy.FluxID.OAuth

    plug Ueberauth

    def request(conn, _params) do
      # Überauth redirects to the authorization URL before we get here when
      # using the FluxID strategy
      redirect(conn, external: OAuth.authorize_url!)
    end

    def callback(%Plug.Conn{assigns: %{ueberauth_auth: auth}} = conn, _params) do
      user_info = auth.info
      user_extra = auth.extra.raw_info
      user_creds = auth.credentials

      # do stuff with information received from FluxID

      redirect(conn, to: "/success-landing-page")
    end

    def callback(%Plug.Conn{assigns: %{ueberauth_failure: _failure}} = conn, _params) do
      errors = failure.errors

      # do stuff with errors

      redirect(conn, to: "/login")
    end
  end
  ```
