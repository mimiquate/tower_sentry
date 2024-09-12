defmodule TowerSentry.Sentry.Client do
  def send(event) do
    Sentry.Client.send_event(event, [])
  end
end
