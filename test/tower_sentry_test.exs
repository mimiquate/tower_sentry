defmodule TowerSentryTest do
  use ExUnit.Case
  doctest TowerSentry

  import ExUnit.CaptureLog, only: [capture_log: 1]

  setup do
    bypass = Bypass.open()

    Sentry.put_config(:dsn, "http://public:secret@localhost:#{bypass.port}/1")
    Sentry.put_config(:send_result, :sync)
    Sentry.put_config(:environment_name, :test)
    Application.put_env(:tower, :reporters, [TowerSentry.Reporter])
    Tower.attach()

    on_exit(fn ->
      Tower.detach()
      reset_sentry_dedupe()
      Sentry.put_config(:dsn, nil)
      Sentry.put_config(:send_result, :none)
    end)

    {:ok, bypass: bypass}
  end

  test "reports arithmetic error", %{bypass: bypass} do
    # ref message synchronization trick copied from
    # https://github.com/PSPDFKit-labs/bypass/issues/112
    parent = self()
    ref = make_ref()

    Bypass.expect_once(bypass, "POST", "/api/1/envelope", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      assert [_id, _header, event] = String.split(body, "\n", trim: true)

      assert(
        {
          :ok,
          %{
            "level" => "error",
            "environment" => "test",
            "exception" => [exception]
          }
        } = Jason.decode(event)
      )

      assert(
        %{
          "type" => "ArithmeticError",
          "value" => "bad argument in arithmetic expression",
          "stacktrace" => %{"frames" => frames}
        } = exception
      )

      assert(
        %{
          "function" => ~s(anonymous fn/0 in TowerSentryTest."test reports arithmetic error"/1),
          "filename" => "test/tower_sentry_test.exs",
          "lineno" => 73
        } = List.last(frames)
      )

      send(parent, {ref, :sent})

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
    end)

    capture_log(fn ->
      in_unlinked_process(fn ->
        1 / 0
      end)
    end)

    assert_receive({^ref, :sent}, 500)
  end

  test "reports throw", %{bypass: bypass} do
    # ref message synchronization trick copied from
    # https://github.com/PSPDFKit-labs/bypass/issues/112
    parent = self()
    ref = make_ref()

    Bypass.expect_once(bypass, "POST", "/api/1/envelope", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      assert [_id, _header, event] = String.split(body, "\n", trim: true)

      assert(
        {
          :ok,
          %{
            "level" => "error",
            "environment" => "test",
            "exception" => [],
            "message" => %{
              "formatted" => "(throw) something"
            },
            "threads" => [%{"stacktrace" => %{"frames" => frames}}]
          }
        } = Jason.decode(event)
      )

      assert(
        %{
          "function" => ~s(anonymous fn/0 in TowerSentryTest."test reports throw"/1),
          "filename" => "test/tower_sentry_test.exs",
          "lineno" => 123
        } = List.last(frames)
      )

      send(parent, {ref, :sent})

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
    end)

    capture_log(fn ->
      in_unlinked_process(fn ->
        throw("something")
      end)
    end)

    assert_receive({^ref, :sent}, 500)
  end

  test "reports abnormal exit", %{bypass: bypass} do
    # ref message synchronization trick copied from
    # https://github.com/PSPDFKit-labs/bypass/issues/112
    parent = self()
    ref = make_ref()

    Bypass.expect_once(bypass, "POST", "/api/1/envelope", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      assert [_id, _header, event] = String.split(body, "\n", trim: true)

      assert(
        {
          :ok,
          %{
            "level" => "error",
            "environment" => "test",
            "exception" => [],
            "message" => %{
              "formatted" => "(exit) :abnormal"
            },
            "threads" => [%{"stacktrace" => %{"frames" => frames}}]
          }
        } = Jason.decode(event)
      )

      assert(
        %{
          "function" => ~s(anonymous fn/0 in TowerSentryTest."test reports abnormal exit"/1),
          "filename" => "test/tower_sentry_test.exs",
          "lineno" => 173
        } = List.last(frames)
      )

      send(parent, {ref, :sent})

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
    end)

    capture_log(fn ->
      in_unlinked_process(fn ->
        exit(:abnormal)
      end)
    end)

    assert_receive({^ref, :sent}, 500)
  end

  test "includes exception request data if available with Plug.Cowboy", %{bypass: bypass} do
    # ref message synchronization trick copied from
    # https://github.com/PSPDFKit-labs/bypass/issues/112
    parent = self()
    ref = make_ref()
    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/arithmetic-error"

    Bypass.expect_once(bypass, "POST", "/api/1/envelope", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      assert [_id, _header, event] = String.split(body, "\n", trim: true)

      assert(
        {
          :ok,
          %{
            "level" => "error",
            "environment" => "test",
            "exception" => [exception],
            "request" => %{
              "method" => "GET",
              "url" => ^url,
              "headers" => %{"user-agent" => "httpc client"}
            }
          }
        } = Jason.decode(event)
      )

      assert(
        %{
          "type" => "ArithmeticError",
          "value" => "bad argument in arithmetic expression",
          "stacktrace" => %{"frames" => frames}
        } = exception
      )

      assert(
        %{
          "function" => "anonymous fn/2 in TowerSentry.ErrorTestPlug.do_match/4",
          "filename" => "test/support/error_test_plug.ex",
          "lineno" => 8
        } = List.last(frames)
      )

      send(parent, {ref, :sent})

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
    end)

    start_supervised!(
      {Plug.Cowboy, plug: TowerSentry.ErrorTestPlug, scheme: :http, port: plug_port}
    )

    capture_log(fn ->
      {:ok, _response} = :httpc.request(:get, {url, [{~c"user-agent", "httpc client"}]}, [], [])
    end)

    assert_receive({^ref, :sent}, 500)
  end

  test "includes throw request data if available with Plug.Cowboy", %{bypass: bypass} do
    # ref message synchronization trick copied from
    # https://github.com/PSPDFKit-labs/bypass/issues/112
    parent = self()
    ref = make_ref()
    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/uncaught-throw"

    Bypass.expect_once(bypass, "POST", "/api/1/envelope", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      assert [_id, _header, event] = String.split(body, "\n", trim: true)

      assert(
        {
          :ok,
          %{
            "level" => "error",
            "environment" => "test",
            "exception" => [],
            "message" => %{
              "formatted" => "(throw) from inside a plug"
            },
            "threads" => [%{"stacktrace" => %{"frames" => frames}}],
            "request" => %{
              "method" => "GET",
              "url" => ^url,
              "headers" => %{"user-agent" => "httpc client"}
            }
          }
        } = Jason.decode(event)
      )

      assert(
        %{
          "function" => "anonymous fn/2 in TowerSentry.ErrorTestPlug.do_match/4",
          "filename" => "test/support/error_test_plug.ex",
          "lineno" => 14
        } = List.last(frames)
      )

      send(parent, {ref, :sent})

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
    end)

    start_supervised!(
      {Plug.Cowboy, plug: TowerSentry.ErrorTestPlug, scheme: :http, port: plug_port}
    )

    capture_log(fn ->
      {:ok, _response} = :httpc.request(:get, {url, [{~c"user-agent", "httpc client"}]}, [], [])
    end)

    assert_receive({^ref, :sent}, 500)
  end

  test "includes abnormal exit request data if available with Plug.Cowboy", %{bypass: bypass} do
    # ref message synchronization trick copied from
    # https://github.com/PSPDFKit-labs/bypass/issues/112
    parent = self()
    ref = make_ref()
    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/abnormal-exit"

    Bypass.expect_once(bypass, "POST", "/api/1/envelope", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      assert [_id, _header, event] = String.split(body, "\n", trim: true)

      assert(
        {
          :ok,
          %{
            "level" => "error",
            "environment" => "test",
            "exception" => [],
            "message" => %{
              "formatted" => "(exit) :abnormal"
            },
            "threads" => [%{"stacktrace" => stacktrace}],
            "request" => %{
              "method" => "GET",
              "url" => ^url,
              "headers" => %{"user-agent" => "httpc client"}
            }
          }
        } = Jason.decode(event)
      )

      # Plug.Cowboy doesn't provide stacktrace for exits
      assert empty_stacktrace?(stacktrace)

      send(parent, {ref, :sent})

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
    end)

    start_supervised!(
      {Plug.Cowboy, plug: TowerSentry.ErrorTestPlug, scheme: :http, port: plug_port}
    )

    capture_log(fn ->
      {:ok, _response} = :httpc.request(:get, {url, [{~c"user-agent", "httpc client"}]}, [], [])
    end)

    assert_receive({^ref, :sent}, 500)
  end

  test "includes exception request data if available with Bandit", %{bypass: bypass} do
    # ref message synchronization trick copied from
    # https://github.com/PSPDFKit-labs/bypass/issues/112
    parent = self()
    ref = make_ref()
    # An ephemeral port hopefully not being in the host running this code
    plug_port = 51111
    url = "http://127.0.0.1:#{plug_port}/arithmetic-error"

    Bypass.expect_once(bypass, "POST", "/api/1/envelope", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      assert [_id, _header, event] = String.split(body, "\n", trim: true)

      assert(
        {
          :ok,
          %{
            "level" => "error",
            "environment" => "test",
            "exception" => [exception],
            "request" => %{
              "method" => "GET",
              "url" => ^url,
              "headers" => %{"user-agent" => "httpc client"}
            }
          }
        } = Jason.decode(event)
      )

      assert(
        %{
          "type" => "ArithmeticError",
          "value" => "bad argument in arithmetic expression",
          "stacktrace" => %{"frames" => frames}
        } = exception
      )

      assert(
        %{
          "function" => "anonymous fn/2 in TowerSentry.ErrorTestPlug.do_match/4",
          "filename" => "test/support/error_test_plug.ex",
          "lineno" => 8
        } = List.last(frames)
      )

      send(parent, {ref, :sent})

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
    end)

    capture_log(fn ->
      start_supervised!({Bandit, plug: TowerSentry.ErrorTestPlug, scheme: :http, port: plug_port})

      {:ok, _response} = :httpc.request(:get, {url, [{~c"user-agent", "httpc client"}]}, [], [])
    end)

    assert_receive({^ref, :sent}, 500)
  end

  test "reports message", %{bypass: bypass} do
    # ref message synchronization trick copied from
    # https://github.com/PSPDFKit-labs/bypass/issues/112
    parent = self()
    ref = make_ref()

    Bypass.expect_once(bypass, "POST", "/api/1/envelope", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      assert [_id, _header, event] = String.split(body, "\n", trim: true)

      assert(
        {
          :ok,
          %{
            "level" => "info",
            "environment" => "test",
            "exception" => [],
            "message" => %{
              "formatted" => "something interesting happened"
            }
          }
        } = Jason.decode(event)
      )

      send(parent, {ref, :sent})

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
    end)

    Tower.handle_message(:info, "something interesting happened")

    assert_receive({^ref, :sent}, 500)
  end

  defp in_unlinked_process(fun) when is_function(fun, 0) do
    {:ok, pid} = Task.Supervisor.start_link()

    pid
    |> Task.Supervisor.async_nolink(fun)
    |> Task.yield()
  end

  defp reset_sentry_dedupe do
    send(Sentry.Dedupe, {:sweep, 0})
    _ = :sys.get_state(Sentry.Dedupe)
  end

  # sentry-elixir 10.6
  defp empty_stacktrace?(nil), do: true
  # sentry-elixir 10.7
  # https://github.com/getsentry/sentry-elixir/pull/775
  defp empty_stacktrace?(%{"frames" => nil}), do: true
  defp empty_stacktrace?(_), do: false
end
