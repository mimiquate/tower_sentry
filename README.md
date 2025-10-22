# TowerSentry

[![ci](https://github.com/mimiquate/tower_sentry/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/mimiquate/tower_sentry/actions?query=branch%3Amain)
[![Hex.pm](https://img.shields.io/hexpm/v/tower_sentry.svg)](https://hex.pm/packages/tower_sentry)
[![Documentation](https://img.shields.io/badge/Documentation-purple.svg)](https://hexdocs.pm/tower_sentry)

Elixir error tracking and reporting to [Sentry](https://sentry.io).

[Tower](https://github.com/mimiquate/tower) reporter for Sentry.

## Installation

Package can be installed by adding `tower_sentry` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:tower_sentry, "~> 0.3.5"}
  ]
end
```

## Setup

### Option A: Automated setup

```sh
$ mix tower_sentry.install
```

### Option B: Manual setup

Tell `Tower` to inform `TowerSentry` reporter about errors.

```elixir
# config/config.exs

config(
  :tower,
  :reporters,
  [
    # along any other possible reporters
    TowerSentry
  ]
)
```

And configure `:tower_sentry` (see [below](#configuration) for details on the available configuration options).

```elixir
# config/runtime.exs

if config_env() == :prod do
  config :tower_sentry,
    dsn: System.get_env("SENTRY_DSN"),
    environment_name: System.get_env("DEPLOYMENT_ENV", to_string(config_env()))
end
```

## Reporting

That's it.
There's no extra source code needed to get reports in Sentry UI.

Tower will automatically report any errors (exceptions, throws or abnormal exits) occurring in your application.
That includes errors in any plug call (including Phoenix), Oban jobs, async task or any other Elixir process.

Some HTTP request data will automatically be included in the report if a `Plug.Conn` if available when Tower handles
the error, e.g. when an exception occurs in a web request.

### Manual reporting

You can manually report errors just by informing `Tower` about any manually caught exceptions, throws or abnormal exits.

```elixir
try do
  # possibly crashing code
rescue
  exception ->
    Tower.report_exception(exception, __STACKTRACE__)
end
```

More details on https://hexdocs.pm/tower/Tower.html#module-manual-reporting.

## Configuration

`TowerSentry` supports the following configuration options:

- `:dsn` (`t:String.t/0`) - The DSN for your Sentry project. Setting this option is mandatory. Learn more about DSNs in
  the [official Sentry documentation](https://docs.sentry.io/concepts/key-terms/dsn-explainer/).
- `:environment_name` (`t:String.t/0` or `t:atom/0`) - The current environment name. The default value is
  `"production"`. Learn more about environments in the [official Sentry documentation](https://docs.sentry.io/concepts/key-terms/environments/).

> #### Note on configuring the `:sentry` app directly {: .warning}
>
> `TowerSentry` currently depends on the [official Sentry SDK for Elixir](`e:sentry:readme.html`) for some internal
> functionality. It is however considered to be an implementation detail of `TowerSentry`.
>
> This means that while setting some config options in the `:sentry` application directly _will_ work and affect the
> reported event (outside of the options listed above, which `TowerSentry` overrides), you are doing so at your own
> risk; the `:sentry` dependency could be removed at any time in favor of a home grown implementation.
>
> Also note that setting `:sentry` configuration options that affect event collection or filtering will have no effect
> as this is entirely handled by [Tower](`e:tower:Tower.html`).

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
