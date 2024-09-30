defmodule TowerSentry do
  @moduledoc """
  Elixir error tracking and reporting to [Sentry](https://sentry.io).

  A Sentry reporter for `Tower`.

  ## Example

      config :tower, :reporters, [TowerSentry]
  """

  @behaviour Tower.Reporter

  @impl true
  def report_event(event) do
    TowerSentry.Reporter.report_event(event)
  end
end
