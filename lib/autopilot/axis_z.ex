defmodule Autopilot.AxisZ do
  @moduledoc false

  use Autopilot.PidController

  def sensor_name, do: {:axis, :z}

  def set_output!(output, current_rate) do
    output = Float.round(output, 2)
    current_rate = Float.round(current_rate, 2)

    cond do
      current_rate == output -> :ok
      current_rate < output -> Autopilot.Simulation.translate(:down)
      current_rate > output -> Autopilot.Simulation.translate(:up)
    end
  end
end
