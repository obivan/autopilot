defmodule Autopilot.Simulation do
  @moduledoc false

  use GenServer
  import Hound.Matchers
  import Hound.Helpers.{Navigation, Element, Page}
  require Logger

  # Client

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @spec telemetry(:roll | :pitch | :yaw | {:axis, :x | :y | :z}) :: list()
  def telemetry(sensor) do
    GenServer.call(__MODULE__, {:telemetry, sensor}, 5000)
  end

  @spec roll(:clockwise | :counter_clockwise) :: :ok
  def roll(direction) do
    GenServer.cast(__MODULE__, {:pilot, :roll, direction})
  end

  @spec pitch(:up | :down) :: :ok
  def pitch(direction) do
    GenServer.cast(__MODULE__, {:pilot, :pitch, direction})
  end

  @spec yaw(:left | :right) :: :ok
  def yaw(direction) do
    GenServer.cast(__MODULE__, {:pilot, :yaw, direction})
  end

  @spec translate(:up | :down | :left | :right | :forward | :backward) :: :ok
  def translate(direction) do
    GenServer.cast(__MODULE__, {:pilot, :translate, direction})
  end

  # Server (callbacks)

  @impl true
  def init(:ok) do
    Hound.Helpers.Session.start_session(browser: "chrome")
    {:ok, :initializing, {:continue, :initialize_simulation}}
  end

  @impl true
  def terminate(_reason, _state) do
    Hound.Helpers.Session.end_session()
  end

  @impl true
  def handle_continue(:initialize_simulation, _state) do
    navigate_to("https://iss-sim.spacex.com/")
    wait_for(fn -> visible_in_page?(~r/begin/iu) end)
    click({:id, "begin-button"})

    # Wait for fancy animation
    :timer.sleep(:timer.seconds(8))

    {:noreply, :ready}
  end

  @impl true
  def handle_call({:telemetry, :roll}, _from, state) do
    currents = [
      sensor_data(:roll, :error),
      sensor_data(:roll, :rate)
    ]

    {:reply, currents, state}
  end

  @impl true
  def handle_call({:telemetry, :pitch}, _from, state) do
    currents = [
      sensor_data(:pitch, :error),
      sensor_data(:pitch, :rate)
    ]

    {:reply, currents, state}
  end

  @impl true
  def handle_call({:telemetry, :yaw}, _from, state) do
    currents = [
      sensor_data(:yaw, :error),
      sensor_data(:yaw, :rate)
    ]

    {:reply, currents, state}
  end

  @impl true
  def handle_call({:telemetry, {:axis, :x}}, _from, state) do
    {:reply, [sensor_data(:position, :x)], state}
  end

  @impl true
  def handle_call({:telemetry, {:axis, :y}}, _from, state) do
    {:reply, [sensor_data(:position, :y)], state}
  end

  @impl true
  def handle_call({:telemetry, {:axis, :z}}, _from, state) do
    {:reply, [sensor_data(:position, :z)], state}
  end

  @impl true
  def handle_cast({:pilot, device, direction}, state) do
    actuator_action(device, direction)
    {:noreply, state}
  end

  # Implementation

  defp sensor_xpath(:roll, :error), do: ~s(//*[@id="roll"]/div[1])
  defp sensor_xpath(:roll, :rate), do: ~s(//*[@id="roll"]/div[2])

  defp sensor_xpath(:pitch, :error), do: ~s(//*[@id="pitch"]/div[1])
  defp sensor_xpath(:pitch, :rate), do: ~s(//*[@id="pitch"]/div[2])

  defp sensor_xpath(:yaw, :error), do: ~s(//*[@id="yaw"]/div[1])
  defp sensor_xpath(:yaw, :rate), do: ~s(//*[@id="yaw"]/div[2])

  defp sensor_xpath(:position, :x), do: ~s(//*[@id="x-range"]/div)
  defp sensor_xpath(:position, :y), do: ~s(//*[@id="y-range"]/div)
  defp sensor_xpath(:position, :z), do: ~s(//*[@id="z-range"]/div)

  defp sensor_data(sensor, dimension) do
    current_readings =
      find_element(:xpath, sensor_xpath(sensor, dimension))
      |> inner_text

    {sensor, dimension, current_readings}
  end

  defp actuator_xpath(:roll, :clockwise), do: ~s(//*[@id="roll-right-button"])
  defp actuator_xpath(:roll, :counter_clockwise), do: ~s(//*[@id="roll-left-button"])

  defp actuator_xpath(:pitch, :up), do: ~s(//*[@id="pitch-up-button"])
  defp actuator_xpath(:pitch, :down), do: ~s(//*[@id="pitch-down-button"])

  defp actuator_xpath(:yaw, :left), do: ~s(//*[@id="yaw-left-button"])
  defp actuator_xpath(:yaw, :right), do: ~s(//*[@id="yaw-right-button"])

  defp actuator_xpath(:translate, :up), do: ~s(//*[@id="translate-up-button"])
  defp actuator_xpath(:translate, :down), do: ~s(//*[@id="translate-down-button"])
  defp actuator_xpath(:translate, :left), do: ~s(//*[@id="translate-left-button"])
  defp actuator_xpath(:translate, :right), do: ~s(//*[@id="translate-right-button"])
  defp actuator_xpath(:translate, :forward), do: ~s(//*[@id="translate-forward-button"])
  defp actuator_xpath(:translate, :backward), do: ~s(//*[@id="translate-backward-button"])

  defp actuator_action(device, direction) do
    try do
      click({:xpath, actuator_xpath(device, direction)})
    catch
      kind, failure ->
        Logger.debug(device: device, kind: kind, failure: failure)
        :actuator_error
    end
  end

  defp wait_for(fun) do
    if fun.() do
      :ok
    else
      :timer.sleep(200)
      wait_for(fun)
    end
  end
end
