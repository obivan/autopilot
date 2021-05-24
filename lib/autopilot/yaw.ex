defmodule Autopilot.Yaw do
  @moduledoc false

  use Autopilot.PidController

  def sensor_name, do: :yaw

  def set_output!(output, current_rate) do
    output = Float.round(output, 2)

    cond do
      current_rate == output -> :ok
      current_rate < output -> Autopilot.Simulation.yaw(:right)
      current_rate > output -> Autopilot.Simulation.yaw(:left)
    end
  end
end
