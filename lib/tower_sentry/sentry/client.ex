defmodule TowerSentry.Sentry.Client do
  @moduledoc false

  def send(event) do
    Sentry.put_config(:dsn, Application.fetch_env!(:tower_sentry, :dsn))

    Sentry.Client.send_event(event, [])
  end
end
