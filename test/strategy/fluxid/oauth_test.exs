defmodule Ueberauth.Strategy.FluxID.OAuthTest do
  use ExUnit.Case

  alias Ueberauth.Strategy.FluxID.OAuth

  setup(tags) do
    if tags[:no_configuration] do
      config = Application.get_env(:ueberauth, Ueberauth.Strategy.FluxID.OAuth)
      Application.put_env(:ueberauth, Ueberauth.Strategy.FluxID.OAuth, nil)

      on_exit(fn ->
        Application.put_env(:ueberauth, Ueberauth.Strategy.FluxID.OAuth, config)
      end)
    end

    :ok
  end

  @tag no_configuration: true
  test "#client no configuration error" do
    Application.put_env(:ueberauth, Ueberauth.Strategy.FluxID.OAuth, nil)

    assert_raise OAuth.ConfigError, fn ->
      OAuth.client
    end
  end
end
