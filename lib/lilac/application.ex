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
      {Lilac.ConvertingSupervisor, name: ConvertingSupervisor}
    ]

    # Start the indexing server
    {:ok, _} = GenServer.start_link(Lilac.Servers.Indexing, :ok, name: IndexingServer)
    # Start the counting server
    {:ok, _} = GenServer.start_link(Lilac.Servers.Counting, :ok, name: CountingServer)

    LilacWeb.Initializer.initialize()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Lilac.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LilacWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
