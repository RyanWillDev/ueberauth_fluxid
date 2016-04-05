defmodule Ueberauth.Strategy.FluxIDTest do
  use ExUnit.Case
  use Plug.Test

  alias SpecRouter

  @router SpecRouter.init([])

  setup(tags) do
    if tags[:oauth_mock] do
      OAuthMock.setup(tags[:oauth_mock])
      on_exit(fn -> OAuthMock.teardown end)
    end

    cond do
      tags[:request_phase] -> request_phase_setup
      tags[:callback_phase] -> callback_phase_setup
      true -> :ok
    end
  end

  defp request_phase_setup do
    conn = conn(:get, "/auth/flux")
    |> SpecRouter.call(@router)

    {:ok, conn: conn}
  end

  defp callback_phase_setup do
    query_params = %{
      code: "fluxid_code"
    }

    conn = conn(:get, "/auth/flux/callback", query_params)
    |> SpecRouter.call(@router)

    {:ok, conn: conn}
  end

  @tag request_phase: true
  test "#handle_request!", %{conn: conn} do
    [location_resp_header | _] = get_resp_header(conn, "location")

    assert conn.status == 302
    assert location_resp_header == "https://id.fluxhq.io/oauth/authorize?" <>
      "client_id=fluxid_client_id&" <>
      "redirect_uri=http%3A%2F%2Flocalhost%3A4000%2Fauth%2Fflux%2Fcallback&" <>
      "response_type=code"
  end

  @tag callback_phase: true, oauth_mock: {:valid_access_token, :success}
  test "#handle_callback! success", %{conn: conn} do
    auth = conn.assigns.ueberauth_auth
    info = auth.info
    credentials = auth.credentials
    extra = auth.extra.raw_info

    assert auth.uid == 327

    assert info.name == "Jordan Davis"
    assert info.email == "jordan.davis@metova.com"

    assert credentials.token == "valid_access_token"
    assert credentials.refresh_token == "fluxid_refresh_token"
    assert credentials.token_type == "Bearer"
    assert credentials.expires == true
    assert credentials.expires_at == 1459656310
    assert credentials.scopes == "public"

    assert extra.admin == true
    assert extra.locked == false

    assert conn.private.fluxid_user == nil
    assert conn.private.fluxid_token == nil
  end

  @tag callback_phase: true, oauth_mock: {:valid_access_token, :unauthorized}
  test "#handle_callback! unauthorized failure", %{conn: conn} do
    [error | _] = conn.assigns.ueberauth_failure.errors

    assert error.message_key == "access_token"
    assert error.message == "Unauthorized"
  end

  @tag callback_phase: true, oauth_mock: {:valid_access_token, :server_error}
  test "#handle_callback! server error failure", %{conn: conn} do
    [error | _] = conn.assigns.ueberauth_failure.errors

    assert error.message_key == "server_error"
    assert error.message == "Server error"
  end

  @tag callback_phase: true, oauth_mock: {:valid_access_token, :error}
  test "#handle_callback! error failure", %{conn: conn} do
    [error | _] = conn.assigns.ueberauth_failure.errors

    assert error.message_key == "OAuth2"
    assert error.message == :timeout
  end

  @tag callback_phase: true, oauth_mock: {:valid_access_token, :unknown}
  test "#handle_callback! unknown error failure", %{conn: conn} do
    [error | _] = conn.assigns.ueberauth_failure.errors

    assert error.message_key == "unknown"
    assert error.message == "Unknown error"
  end

  @tag callback_phase: true, oauth_mock: {:invalid_access_token, :invalid_grant}
  test "#handle_callback! no access token failure", %{conn: conn} do
    [error | _] = conn.assigns.ueberauth_failure.errors

    assert error.message_key == "invalid_grant"
    assert error.message == "The provided authorization grant is invalid, " <>
      "expired, revoked, does not match the redirection URI used in the " <>
      "authorization request, or was issued to another client."
  end

  test "#handle_callback! no code failure" do
    conn = conn(:get, "/auth/flux/callback")
    |> SpecRouter.call(@router)

    [error | _] = conn.assigns.ueberauth_failure.errors

    assert error.message_key == "missing_code"
    assert error.message == "No code received"
  end
end
