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

      if config_env() == :prod do
        config :tower_sentry,
          dsn: System.get_env("SENTRY_DSN"),
          environment_name: System.get_env("SENTRY_ENVIRONMENT")
      end
      """)
    end

    test "modifies existing tower configs if available" do
      test_project(
        files: %{
          "config/config.exs" => """
          import Config

          config :tower, reporters: [TowerEmail]
          """,
          "config/runtime.exs" => """
          import Config
          """
        }
      )
      |> Igniter.compose_task("tower_sentry.install", [])
      |> assert_has_patch("config/config.exs", """
      |import Config
      |
      - |config :tower, reporters: [TowerEmail]
      + |config :tower, reporters: [TowerEmail, TowerSentry]
      """)
      |> assert_has_patch("config/runtime.exs", """
      |import Config
      |
      + |if config_env() == :prod do
      + |  config :tower_sentry,
      + |    dsn: System.get_env("SENTRY_DSN"),
      + |    environment_name: System.get_env("SENTRY_ENVIRONMENT")
      + |end
      + |
      """)
    end

    test "modifies existing tower configs if config_env() == :prod block exists" do
      test_project(
        files: %{
          "config/config.exs" => """
          import Config

          config :tower, reporters: [TowerEmail]
          """,
          "config/runtime.exs" => """
          import Config

          if config_env() == :prod do
            IO.puts("hello")
          end
          """
        }
      )
      |> Igniter.compose_task("tower_sentry.install", [])
      |> assert_has_patch("config/config.exs", """
      |import Config
      |
      - |config :tower, reporters: [TowerEmail]
      + |config :tower, reporters: [TowerEmail, TowerSentry]
      """)
      |> assert_has_patch("config/runtime.exs", """
      |if config_env() == :prod do
      |  IO.puts("hello")
      + |
      + |  config :tower_sentry,
      + |    dsn: System.get_env("SENTRY_DSN"),
      + |    environment_name: System.get_env("SENTRY_ENVIRONMENT")
      |end
      |
      """)
    end

    test "does not modify existing tower_sentry configs if config_env() == :prod block exists" do
      test_project(
        files: %{
          "config/config.exs" => """
          import Config

          config :tower, reporters: [TowerEmail, TowerSentry]
          """,
          "config/runtime.exs" => """
          import Config

          if config_env() == :prod do
            config :tower_sentry,
              dsn: System.get_env("SENTRY_DSN"),
              environment_name: System.get_env("SENTRY_ENVIRONMENT")
          end
          """
        }
      )
      |> Igniter.compose_task("tower_sentry.install", [])
      |> assert_unchanged()
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
