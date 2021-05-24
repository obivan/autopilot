defmodule Autopilot.Pitch do
  @moduledoc false

  use Autopilot.PidController

  def sensor_name, do: :pitch

  def set_output!(output, current_rate) do
    output = Float.round(output, 2)

    cond do
      current_rate == output -> :ok
      current_rate < output -> Autopilot.Simulation.pitch(:down)
      current_rate > output -> Autopilot.Simulation.pitch(:up)
    end
  end
end
