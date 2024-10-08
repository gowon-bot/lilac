defmodule Lilac.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Lilac.Repo,
      # Start the Telemetry supervisor
      LilacWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Lilac.PubSub},
      # Start the Endpoint (http/https)
      LilacWeb.Endpoint,
      {Absinthe.Subscription, LilacWeb.Endpoint},

      # Start the sync registry
      {Registry, keys: :unique, name: Lilac.Sync.Registry},

      # Start the syncer
      Lilac.Sync.Syncer
    ]

    LilacWeb.Initializer.initialize()

    opts = [strategy: :one_for_one, name: Lilac.Supervisor]
    Supervisor.start_link(children, opts)

    Redix.start_link(host: Application.fetch_env!(:lilac, :redis_host), name: :redix)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated
  @impl true
  def config_change(changed, _new, removed) do
    LilacWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
