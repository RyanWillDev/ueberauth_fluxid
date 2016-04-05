defmodule OAuthMock do
  @valid_access_token %OAuth2.AccessToken{
    access_token: "valid_access_token",
    client: %OAuth2.Client{
      authorize_url: "/oauth/authorize",
      client_id: "fluxid_client_id",
      client_secret: "fluxid_client_secret",
      headers: [],
      params: %{
        "client_id" => "fluxid_client_id",
        "client_secret" => "fluxid_client_secret",
        "code" => "valid_fluxid_code",
        "grant_type" => "authorization_code",
        "redirect_uri" => "http://localhost:4000/auth/flux/callback"
      },
      redirect_uri: "http://localhost:4000/auth/flux/callback",
      site: "https://id.fluxhq.io",
      strategy: Ueberauth.Strategy.FluxID.OAuth,
      token_method: :post,
      token_url: "/oauth/token"
    },
    expires_at: 1459656310,
    other_params: %{"scope" => "public"},
    refresh_token: "fluxid_refresh_token",
    token_type: "Bearer"
  }

  @invalid_access_token %OAuth2.AccessToken{
    access_token: nil,
    client: %OAuth2.Client{
      authorize_url: "/oauth/authorize",
      client_id: "fluxid_client_id",
      client_secret: "fluxid_client_secret",
      headers: [],
      params: %{
        "client_id" => "fluxid_client_id",
        "client_secret" => "fluxid_client_secret",
        "code" => "invalid_fluxid_code",
        "grant_type" => "authorization_code",
        "redirect_uri" => "http://localhost:4000/auth/flux/callback"
      },
      redirect_uri: "http://localhost:4000/auth/flux/callback",
      site: "https://id.fluxhq.io",
      strategy: Ueberauth.Strategy.FluxID.OAuth,
      token_method: :post,
      token_url: "/oauth/token"
    },
    expires_at: nil,
    other_params: %{
      "error" => "invalid_grant",
      "error_description" => "The provided authorization grant is invalid, " <>
        "expired, revoked, does not match the redirection URI used in the " <>
        "authorization request, or was issued to another client."
    },
    refresh_token: nil,
    token_type: "Bearer"
  }

  @oauth_success_response %OAuth2.Response{
    body: %{
      "admin" => true,
      "email" => "jordan.davis@metova.com",
      "id" => 327,
      "locked" => false,
      "name" => "Jordan Davis"
    },
    headers: [],
    status_code: 200
  }

  @oauth_unauthorized_response %OAuth2.Response{
    body: " ",
    headers: [],
    status_code: 401
  }

  @oauth_server_error_response %OAuth2.Response{
    body: " ",
    headers: [],
    status_code: 500
  }

  @oauth_unknown_error_response %OAuth2.Response{
    body: " ",
    headers: [],
    status_code: 400
  }

  @oauth_error %OAuth2.Error{reason: :timeout}

  def setup(mock_settings) do
    :ok = :meck.new(Ueberauth.Strategy.FluxID.OAuth, [:passthrough])
    setup_mock(mock_settings)
    :meck.validate(Ueberauth.Strategy.FluxID.OAuth)
  end

  def teardown do
    :meck.unload
  end

  defp setup_mock({:valid_access_token, :success}) do
    setup_valid_get_token_mock

    :ok = :meck.expect(Ueberauth.Strategy.FluxID.OAuth, :fetch_user,
      fn(_access_token) -> {:ok, @oauth_success_response} end)
  end

  defp setup_mock({:valid_access_token, :unauthorized}) do
    setup_valid_get_token_mock

    :ok = :meck.expect(Ueberauth.Strategy.FluxID.OAuth, :fetch_user,
      fn(_access_token) -> {:ok, @oauth_unauthorized_response} end)
  end

  defp setup_mock({:valid_access_token, :server_error}) do
    setup_valid_get_token_mock

    :ok = :meck.expect(Ueberauth.Strategy.FluxID.OAuth, :fetch_user,
      fn(_access_token) -> {:ok, @oauth_server_error_response} end)
  end

  defp setup_mock({:valid_access_token, :error}) do
    setup_valid_get_token_mock

    :ok = :meck.expect(Ueberauth.Strategy.FluxID.OAuth, :fetch_user,
      fn(_access_token) -> {:error, @oauth_error} end)
  end

  defp setup_mock({:valid_access_token, :unknown}) do
    setup_valid_get_token_mock

    :ok = :meck.expect(Ueberauth.Strategy.FluxID.OAuth, :fetch_user,
      fn(_access_token) -> {:ok, @oauth_unknown_error_response} end)
  end

  defp setup_mock({:invalid_access_token, :invalid_grant}) do
    :ok = :meck.expect(Ueberauth.Strategy.FluxID.OAuth, :get_token!,
      fn(_parameters) -> @invalid_access_token end)
  end

  defp setup_valid_get_token_mock do
    :ok = :meck.expect(Ueberauth.Strategy.FluxID.OAuth, :get_token!,
      fn(_parameters) -> @valid_access_token end)
  end
end
