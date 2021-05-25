defmodule Autopilot.Roll do
  @moduledoc false

  use Autopilot.PidController, sensor: :roll

  def set_output!(output, current_rate) do
    output = Float.round(output, 2)

    cond do
      current_rate == output -> :ok
      current_rate < output -> Autopilot.Simulation.roll(:clockwise)
      current_rate > output -> Autopilot.Simulation.roll(:counter_clockwise)
    end
  end
end
