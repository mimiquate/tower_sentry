%{
  tower_0_7: [{:tower, "~> 0.7.1"}],
  sentry_10: [
    {:sentry, "~> 10.3"},
    {:hackney, "~> 1.25", only: :test}
  ],
  sentry_11: [
    {:sentry, "~> 11.0"},
    {:hackney, "~> 1.25", only: :test}
  ]
}
