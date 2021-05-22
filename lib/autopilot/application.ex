defmodule Autopilot.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Autopilot.Simulation,
      Autopilot.Roll,
      Autopilot.Pitch,
      Autopilot.Yaw,
      Autopilot.AxisY,
      Autopilot.AxisZ,
      {Autopilot.AxisX, kp: 0.01, bias: 0.1, poll_interval: 500}
      # Starts a worker by calling: Autopilot.Worker.start_link(arg)
      # {Autopilot.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Autopilot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
