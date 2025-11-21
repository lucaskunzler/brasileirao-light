defmodule BrasileiraoLight.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      BrasileiraoLightWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:brasileirao_light, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: BrasileiraoLight.PubSub},
      # Start a worker by calling: BrasileiraoLight.Worker.start_link(arg)
      # {BrasileiraoLight.Worker, arg},
      # Start to serve requests, typically the last entry
      BrasileiraoLightWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BrasileiraoLight.Supervisor]
    BrasileiraoLight.Data.warmup()
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BrasileiraoLightWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
