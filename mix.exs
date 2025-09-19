defmodule TowerSentry.MixProject do
  use Mix.Project

  @description "Error tracking and reporting to Sentry"
  @source_url "https://github.com/mimiquate/tower_sentry"
  @version "0.3.4"

  def project do
    [
      app: :tower_sentry,
      description: @description,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),

      # Docs
      name: "TowerSentry",
      source_url: @source_url,
      docs: docs()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      env: [dsn: nil, environment_name: nil]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tower, "~> 0.7.1 or ~> 0.8.0"},
      {:sentry, "~> 10.3 or ~> 11.0"},

      # Optional
      {:igniter, "~> 0.6", optional: true},

      # Dev
      {:ex_doc, "~> 0.38.2", only: :dev, runtime: false},
      {:blend, "~> 0.5.0", only: :dev},

      # Test
      {:hackney, "~> 1.20", only: :test},
      {:test_server, "~> 0.1.18", only: :test},
      {:plug_cowboy, "~> 2.7", only: :test},
      {:bandit, "~> 1.5", only: :test}
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      extras: ["README.md"]
    ]
  end
end
