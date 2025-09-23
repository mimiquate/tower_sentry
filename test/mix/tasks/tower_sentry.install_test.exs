if Code.ensure_loaded?(Tower.Igniter) do
  defmodule Mix.Tasks.TowerSentry.Task.InstallTest do
    use ExUnit.Case, async: true
    import Igniter.Test

    test "generates everything from scratch" do
      test_project()
      |> Igniter.compose_task("tower_sentry.install", [])
      |> assert_creates("config/config.exs", """
      import Config
      config :tower, reporters: [TowerSentry]
      """)
      |> assert_creates("config/runtime.exs", """
      import Config

      config :tower_sentry,
        dsn: System.get_env("SENTRY_DSN"),
        environment_name: System.get_env("DEPLOYMENT_ENV", to_string(config_env()))
      """)
    end

    test "is idempotent" do
      test_project()
      |> Igniter.compose_task("tower_sentry.install", [])
      |> apply_igniter!()
      |> Igniter.compose_task("tower_sentry.install", [])
      |> assert_unchanged()
    end
  end
end
