defmodule Ueberauth.Strategy.FluxID do
  @moduledoc """
  FluxID strategy for Ueberauth.

  Add `flux` to your configuration:

  config :ueberauth, Ueberauth,
    providers: [
      flux: {Ueberauth.Strategy.FluxID, []}
    ]
  """

  use Ueberauth.Strategy

  alias Ueberauth.Auth.Credentials
  alias Ueberauth.Auth.Info
  alias Ueberauth.Auth.Extra

  alias Ueberauth.Strategy.FluxID

  @access_token_path "/api/v1/me"

  @doc """
  Handles initial request for FluxID authentication.
  """
  def handle_request!(conn) do
    redirect!(conn, FluxID.OAuth.authorize_url!)
  end

  @doc """
  Handles callback from FluxID.
  """
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    token = FluxID.OAuth.get_token!(code: code)

    conn = put_private(conn, :fluxid_token, token)

    if token.access_token == nil do
      error_title = token.other_params["error"]
      error_description = token.other_params["error_description"]

      set_errors!(conn, [error(error_title, error_description)])
    else
      case FluxID.OAuth.fetch_user(token) do
        {:ok, %OAuth2.Response{status_code: status_code, body: user}}
          when status_code in 200..399 ->
            put_private(conn, :fluxid_user, user)
        {:ok, %OAuth2.Response{status_code: 401}} ->
          set_errors!(conn, [error("access_token", "Unauthorized")])
        {:ok, %OAuth2.Response{status_code: status_code}}
          when status_code in 500..599 ->
            set_errors!(conn, [error("server_error", "Server error")])
        {:error, %OAuth2.Error{reason: reason}} ->
          set_errors!(conn, [error("OAuth2", reason)])
        _ ->
          set_errors!(conn, [error("unknown", "Unknown error")])
      end
    end
  end

  @doc false
  def handle_callback!(conn) do
    set_errors!(conn, [error("missing_code", "No code received")])
  end

  @doc false
  def handle_cleanup!(conn) do
    conn
    |> put_private(:fluxid_user, nil)
    |> put_private(:fluxid_token, nil)
  end

  @doc """
  Fetches the uid field from the response.
  """
  def uid(conn) do
    conn.private.fluxid_user["id"]
  end

  @doc """
  Fetches the fields to populate the credentials section of the `
  Ueberauth.Auth` struct.
  """
  def credentials(conn) do
    token = conn.private.fluxid_token

    %Credentials{
      token: token.access_token,
      refresh_token: token.refresh_token,
      token_type: token.token_type,
      expires: !!token.expires_at,
      expires_at: token.expires_at,
      scopes: token.other_params["scope"]
    }
  end

  @doc """
  Fetches the fields to populate the info section of the `Ueberauth.Auth`
  struct.  Includes user information such as name and email.
  """
  def info(conn) do
    user = conn.private.fluxid_user

    %Info{
      name: user["name"],
      email: user["email"]
    }
  end

  @doc """
  Fetches the fields to populate the extra section of the `Ueberauth.Auth`
  struct.  Includes miscellaneous information such as admin and locked
  account statuses.
  """
  def extra(conn) do
    user = conn.private.fluxid_user

    %Extra{
      raw_info: %{
        admin: user["admin"],
        locked: user["locked"]
      }
    }
  end
end
