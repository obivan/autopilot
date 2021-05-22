defmodule Autopilot.AxisX do
  @moduledoc false

  use Autopilot.PidController

  def sensor_name, do: {:axis, :x}

  def set_output(output, current_rate) do
    output = Float.round(output, 2)
    current_rate = Float.round(current_rate, 2)

    cond do
      current_rate == output -> :ok
      current_rate < output -> Autopilot.Simulation.translate(:forward)
      current_rate > output -> Autopilot.Simulation.translate(:backward)
    end
  end
end
