defmodule TowerSentry.Reporter do
  @behaviour Tower.Reporter

  @impl true
  def report_event(%Tower.Event{} = tower_event) do
    if enabled?() do
      tower_event
      |> TowerSentry.Sentry.Event.from_tower_event()
      |> TowerSentry.Sentry.Client.send()
    else
      IO.puts("TowerSentry NOT enabled, ignoring...")
    end
  end

  defp enabled? do
    Sentry.Config.dsn()
  end
end
