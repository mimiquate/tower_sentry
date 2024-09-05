defmodule TowerSentry.MixProject do
  use Mix.Project

  @description "Error tracking and reporting to Sentry"
  @source_url "https://github.com/mimiquate/tower_sentry"
  @version "0.1.0"

  def project do
    [
      app: :tower_sentry,
      description: @description,
      version: @version,
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:tower, "~> 0.5.0"},
      {:sentry, "~> 10.5"},

      # Dev
      {:ex_doc, "~> 0.34.2", only: :dev, runtime: false},
      {:blend, "~> 0.4.0", only: :dev},

      # Test
      {:jason, "~> 1.4", only: :test},
      {:hackney, "~> 1.20", only: :test},
      {:bypass, "~> 2.1", only: :test},
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
end
