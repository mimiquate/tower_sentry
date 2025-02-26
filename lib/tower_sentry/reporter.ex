defmodule TowerSentry.Reporter do
  @moduledoc false

  def report_event(%Tower.Event{} = tower_event) do
    if enabled?() do
      event = TowerSentry.Sentry.Event.from_tower_event(tower_event)
      async(fn -> TowerSentry.Sentry.Client.send(event) end)
    else
      IO.puts("TowerSentry NOT enabled, ignoring...")
    end
  end

  defp enabled? do
    !!Application.get_env(:tower_sentry, :dsn)
  end

  defp async(fun) do
    Tower.TaskSupervisor
    |> Task.Supervisor.start_child(fun)
  end
end
