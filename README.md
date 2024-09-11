# TowerSentry

[![ci](https://github.com/mimiquate/tower_sentry/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/mimiquate/tower_sentry/actions?query=branch%3Amain)
[![Hex.pm](https://img.shields.io/hexpm/v/tower_sentry.svg)](https://hex.pm/packages/tower_sentry)
[![Documentation](https://img.shields.io/badge/Documentation-purple.svg)](https://hexdocs.pm/tower_sentry)

[Tower](https://github.com/mimiquate/tower) reporter for [Sentry](https://sentry.io).

## Installation

Package can be installed by adding `tower_sentry` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tower_sentry, "~> 0.1.0"}
  ]
end
```

## Usage

First, attach `Tower` to automatically capture errors.

```elixir
# lib/<your_app>/application.ex

defmodule YourApp.Application do
  def start(_type, _args) do
    Tower.attach()

    # rest of your code
  end
```

Then tell `Tower` to inform `TowerSentry` reporter about them.

```elixir
# config/config.exs

config(
  :tower,
  :reporters,
  [
    # along any other possible reporters
    TowerSentry.Reporter
  ]
)
```

And finally configure `:sentry` dsn.

```elixir
# config/runtime.exs

if config_env() == :prod do
  config :sentry, dsn: System.get_env("SENTRY_DSN")
end
```

Note that `tower_sentry` uses `tower` to capture errors and `sentry` package to report remotely to Sentry servers.
So any `sentry` package configuration that affects it's capturing behavior won't have any effect when using it
via `tower_sentry`.

That's it.

It will try report any errors (exceptions, throws or abnormal exits) within your application. That includes errors in
any plug call (including Phoenix), Oban job, async task or any other Elixir process.

Some HTTP request data will automatically be included in the report if a `Plug.Conn` if available when handling the error.

### Manual reporting

You can manually report errors just by informing `Tower` about any manually caught exceptions, throws or abnormal exits.


```elixir
try do
  # possibly crashing code
catch
  kind, reason ->
    Tower.handle_caught(kind, reason, __STACKTRACE__)
end
```

More details on https://hexdocs.pm/tower/Tower.html#module-manual-handling.

## License

Copyright 2024 Mimiquate

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
