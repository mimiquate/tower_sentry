defmodule TowerSentry.Reporter do
  @moduledoc false

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
    !!Application.get_env(:tower_sentry, :dsn)
  end
end
