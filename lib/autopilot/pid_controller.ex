defmodule Autopilot.PidController do
  @moduledoc false

  defmacro __using__([sensor: sensor] = _opts) do
    quote do
      use GenServer
      require Logger

      @wake_term :work
      @sensor_name unquote(sensor)

      # Client

      def start_link(opts) do
        GenServer.start_link(__MODULE__, opts)
      end

      # Server (callbacks)

      @impl true
      def init(opts) do
        state = %{
          previous_error: 0.0,
          previous_integral: 0.0,
          last_update: Time.utc_now(),
          poll_interval: Keyword.get(opts, :poll_interval, 250),
          kp: Keyword.get(opts, :kp, 0.1),
          kd: Keyword.get(opts, :kd, 0.0),
          ki: Keyword.get(opts, :ki, 0.0),
          bias: Keyword.get(opts, :bias, 0.0)
        }

        Process.send_after(self(), @wake_term, state.poll_interval)

        {:ok, state}
      end

      @impl true
      def handle_info(:work, state) do
        new_state =
          try do
            {error, rate} = read_signal!(@sensor_name, state)
            {output, new_state} = calculate_output(error, state)
            set_output!(output, rate)
            new_state
          catch
            kind, failure ->
              Logger.debug(sensor: @sensor_name, kind: kind, failure: failure)
              state
          end

        Process.send_after(self(), @wake_term, state.poll_interval)
        {:noreply, new_state}
      end

      # Implementation

      defp read_signal!(sensor, state) do
        Autopilot.Simulation.telemetry(sensor)
        |> prepare_signal(state)
      end

      @spec calculate_output(float(), any()) :: {float(), any()}
      defp calculate_output(error, state) do
        time_passed = Time.diff(Time.utc_now(), state.last_update, :millisecond)
        integral = state.previous_integral + error * time_passed
        derivative = (error - state.previous_error) / time_passed
        output = state.kp * error + state.ki * integral + state.kd * derivative + state.bias

        {
          output,
          %{
            state
            | previous_error: error,
              previous_integral: integral,
              last_update: Time.utc_now()
          }
        }
      end

      defp calculate_rate(error, state) do
        space_travel = state.previous_error - error
        time_passed = Time.diff(Time.utc_now(), state.last_update, :millisecond)
        rate = space_travel / time_passed * 900

        rate
      end

      defp prepare_signal([{sensor, :error, error}, {sensor, :rate, rate}], _state) do
        {clean_signal(error), clean_signal(rate)}
      end

      defp prepare_signal([{:position, _axis, error}], state) do
        error = clean_signal(error)
        rate = calculate_rate(error, state)
        {error, rate}
      end

      @spec clean_signal(String.t()) :: float()
      defp clean_signal(signal) do
        with [first_number | _] <- Regex.run(~r"^[-+]?\d*\.\d+|\d+", signal),
             {signal, _} <- Float.parse(first_number) do
          signal
        end
      end
    end
  end

  @callback set_output!(float(), float()) :: any()
end
