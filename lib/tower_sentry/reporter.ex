defmodule TowerSentry.Reporter do
  @moduledoc """
  The reporter module that needs to be added to the list of Tower reporters.

  ## Example

      config :tower, :reporters, [TowerSentry.Reporter]
  """

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
    !!Application.get_env(:tower_sentry, :dsn)
  end
end
