defmodule Ueberauth.Strategy.FluxID.OAuth do
  @moduledoc """
  OAuth2 for FluxID.

  Add `client_id`, `client_secret`, and `redirect_uri` to your configuration:

  config :ueberauth, Ueberauth.Strategy.FluxID.OAuth,
    client_id: System.get_env("FLUXID_CLIENT_ID"),
    client_secret: System.get_env("FLUXID_CLIENT_SECRET"),
    redirect_uri: System.get_env("FLUXID_REDIRECT_URI")
  """
  use OAuth2.Strategy

  alias OAuth2.Client
  alias OAuth2.Strategy.AuthCode

  @defaults [
    strategy: __MODULE__,
    site: "https://id.fluxhq.io",
    headers: [{"Accept", "application/json"}]
  ]

  @access_token_path "/api/v1/me"

  @doc """
  Construct a client for requests to FluxID.

  This will be setup automatically for you in `Ueberauth.Strategy.FluxID`.
  """
  def client do
    if config == nil do
      raise Ueberauth.Strategy.FluxID.OAuth.ConfigError
    end

    @defaults
    |> Keyword.merge(config)
    |> Client.new
  end

  @doc """
  Constructs redirect URL for authenticating a user in FluxID via OAuth2.
  """
  def authorize_url! do
    Client.authorize_url!(client, [])
  end


  @doc """
  Exchanges a code received from FluxID for an access token.
  """
  def get_token!(parameters \\ []) do
    Client.get_token!(client, parameters)
  end

  @doc false
  def authorize_url(client, parameters) do
    AuthCode.authorize_url(client, parameters)
  end

  @doc false
  def get_token(client, parameters, headers) do
    AuthCode.get_token(client, parameters, headers)
  end

  @doc """
  Exchanges an access token received from FluxID for user information.
  """
  def fetch_user(access_token) do
    OAuth2.AccessToken.get(access_token, @access_token_path)
  end

  defp config do
    Application.get_env(:ueberauth, __MODULE__)
  end

  defmodule ConfigError do
    @moduledoc false
    
    defexception message: ":ueberauth, Ueberauth.Strategy.FluxID.OAuth " <>
      "config not defined."
  end
end
