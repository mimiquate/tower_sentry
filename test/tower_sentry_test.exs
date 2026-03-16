defmodule TowerSentryTest do
  use ExUnit.Case
  doctest TowerSentry

  import ExUnit.CaptureLog, only: [capture_log: 1]

  setup do
    {:ok, _test_server} = TestServer.start()

    put_env(:tower_sentry, :dsn, TestServer.url("/1", host: "public:secret@localhost"))
    put_env(:tower_sentry, :environment_name, :test)
    Sentry.put_config(:send_result, :sync)
    put_env(:tower, :reporters, [TowerSentry])

    on_exit(fn ->
      reset_sentry_dedupe()
      Sentry.put_config(:send_result, :none)
    end)
  end

  test "reports arithmetic error" do
    waiting_for(fn done ->
      TestServer.add(
        "/api/1/envelope",
        via: :post,
        to: fn conn ->
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
              "stacktrace" => %{"frames" => frames},
              "mechanism" => %{"handled" => false}
            } = exception
          )

          assert(
            %{
              "function" =>
                ~s(anonymous fn/0 in TowerSentryTest."test reports arithmetic error"/1),
              "filename" => "test/tower_sentry_test.exs",
              "lineno" => 70
            } = List.last(frames)
          )

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
        end
      )

      capture_log(fn ->
        in_unlinked_process(fn ->
          1 / 0
        end)
      end)
    end)
  end

  test "reports throw" do
    waiting_for(fn done ->
      TestServer.add(
        "/api/1/envelope",
        via: :post,
        to: fn conn ->
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
                  "formatted" => "(throw) \"something\""
                },
                "threads" => [%{"stacktrace" => %{"frames" => frames}}]
              }
            } = Jason.decode(event)
          )

          assert(
            %{
              "function" => ~s(anonymous fn/0 in TowerSentryTest."test reports throw"/1),
              "filename" => "test/tower_sentry_test.exs",
              "lineno" => 119
            } = List.last(frames)
          )

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
        end
      )

      capture_log(fn ->
        in_unlinked_process(fn ->
          throw("something")
        end)
      end)
    end)
  end

  test "reports abnormal exit" do
    waiting_for(fn done ->
      TestServer.add(
        "/api/1/envelope",
        via: :post,
        to: fn conn ->
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
              "lineno" => 168
            } = List.last(frames)
          )

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
        end
      )

      capture_log(fn ->
        in_unlinked_process(fn ->
          exit(:abnormal)
        end)
      end)
    end)
  end

  test "includes exception request data if available with Plug.Cowboy" do
    waiting_for(fn done ->
      # An ephemeral port hopefully not being in the host running this code
      plug_port = 51111
      url = "http://127.0.0.1:#{plug_port}/arithmetic-error"

      TestServer.add(
        "/api/1/envelope",
        via: :post,
        to: fn conn ->
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
              "stacktrace" => %{"frames" => frames},
              "mechanism" => %{"handled" => false}
            } = exception
          )

          assert(
            %{
              "function" => "anonymous fn/2 in TowerSentry.ErrorTestPlug.do_match/4",
              "filename" => "test/support/error_test_plug.ex",
              "lineno" => 8
            } = List.last(frames)
          )

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
        end
      )

      start_supervised!(
        {Plug.Cowboy, plug: TowerSentry.ErrorTestPlug, scheme: :http, port: plug_port}
      )

      capture_log(fn ->
        {:ok, _response} = :httpc.request(:get, {url, [{~c"user-agent", "httpc client"}]}, [], [])
      end)
    end)
  end

  test "includes throw request data if available with Plug.Cowboy" do
    waiting_for(fn done ->
      # An ephemeral port hopefully not being in the host running this code
      plug_port = 51111
      url = "http://127.0.0.1:#{plug_port}/uncaught-throw"

      TestServer.add(
        "/api/1/envelope",
        via: :post,
        to: fn conn ->
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
                  "formatted" => "(throw) \"from inside a plug\""
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

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
        end
      )

      start_supervised!(
        {Plug.Cowboy, plug: TowerSentry.ErrorTestPlug, scheme: :http, port: plug_port}
      )

      capture_log(fn ->
        {:ok, _response} = :httpc.request(:get, {url, [{~c"user-agent", "httpc client"}]}, [], [])
      end)
    end)
  end

  test "includes abnormal exit request data if available with Plug.Cowboy" do
    waiting_for(fn done ->
      # An ephemeral port hopefully not being in the host running this code
      plug_port = 51111
      url = "http://127.0.0.1:#{plug_port}/abnormal-exit"

      TestServer.add(
        "/api/1/envelope",
        via: :post,
        to: fn conn ->
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
                "threads" => [thread],
                "request" => %{
                  "method" => "GET",
                  "url" => ^url,
                  "headers" => %{"user-agent" => "httpc client"}
                }
              }
            } = Jason.decode(event)
          )

          # Plug.Cowboy doesn't provide stacktrace for exits
          assert empty_stacktrace?(Map.get(thread, "stacktrace"))

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
        end
      )

      start_supervised!(
        {Plug.Cowboy, plug: TowerSentry.ErrorTestPlug, scheme: :http, port: plug_port}
      )

      capture_log(fn ->
        {:ok, _response} = :httpc.request(:get, {url, [{~c"user-agent", "httpc client"}]}, [], [])
      end)
    end)
  end

  test "includes exception request data if available with Bandit" do
    waiting_for(fn done ->
      # An ephemeral port hopefully not being in the host running this code
      plug_port = 51111
      url = "http://127.0.0.1:#{plug_port}/arithmetic-error"

      TestServer.add(
        "/api/1/envelope",
        via: :post,
        to: fn conn ->
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
              "stacktrace" => %{"frames" => frames},
              "mechanism" => %{"handled" => false}
            } = exception
          )

          assert(
            %{
              "function" => "anonymous fn/2 in TowerSentry.ErrorTestPlug.do_match/4",
              "filename" => "test/support/error_test_plug.ex",
              "lineno" => 8
            } = List.last(frames)
          )

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
        end
      )

      capture_log(fn ->
        start_supervised!(
          {Bandit, plug: TowerSentry.ErrorTestPlug, scheme: :http, port: plug_port}
        )

        {:ok, _response} = :httpc.request(:get, {url, [{~c"user-agent", "httpc client"}]}, [], [])
      end)
    end)
  end

  test "reports message" do
    waiting_for(fn done ->
      TestServer.add(
        "/api/1/envelope",
        via: :post,
        to: fn conn ->
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

          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "123"}))
        end
      )

      Tower.report_message(:info, "something interesting happened")
    end)
  end

  test "logs client request error message" do
    put_env(:sentry, :request_retries, [])

    waiting_for(fn done ->
      TestServer.add(
        "/api/1/envelope",
        via: :post,
        to: fn conn ->
          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(400, Jason.encode!(nil))
        end
      )

      assert capture_log(fn ->
               assert :ok = Tower.report_message(:info, "something")

               Process.sleep(100)
             end) =~ ~r/Failed to send Sentry event/
    end)
  end

  test "logs internal server error" do
    put_env(:sentry, :request_retries, [])

    waiting_for(fn done ->
      TestServer.add(
        "/api/1/envelope",
        via: :post,
        to: fn conn ->
          done.()

          conn
          |> Plug.Conn.put_resp_content_type("application/json")
          |> Plug.Conn.resp(500, Jason.encode!(nil))
        end
      )

      assert capture_log(fn ->
               assert :ok = Tower.report_message(:info, "something")

               Process.sleep(100)
             end) =~ ~r/Failed to send Sentry event/
    end)
  end

  test "logs when network error" do
    put_env(:sentry, :request_retries, [])
    # Point to a localhost port that we know it's not going to work
    put_env(:tower_sentry, :dsn, "http://public:secret@localhost:0/1")

    assert capture_log(fn ->
             assert :ok = Tower.report_message(:info, "something")

             Process.sleep(100)
           end) =~ ~r/Failed to send Sentry event/
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

  # sentry-elixir 10.3 and 10.4
  defp empty_stacktrace?(%{"frames" => []}), do: true
  # sentry-elixir 10.5, 10.6 and 10.8
  defp empty_stacktrace?(nil), do: true
  # sentry-elixir 10.7
  # https://github.com/getsentry/sentry-elixir/pull/775
  defp empty_stacktrace?(%{"frames" => nil}), do: true
  defp empty_stacktrace?(_), do: false

  defp waiting_for(fun) do
    # ref message synchronization trick copied from
    # https://github.com/PSPDFKit-labs/bypass/issues/112
    parent = self()
    ref = make_ref()

    fun.(fn ->
      send(parent, {ref, :sent})
    end)

    assert_receive({^ref, :sent}, 500)
  end

  defp put_env(app, key, value) do
    original_value = Application.get_env(app, key)
    Application.put_env(app, key, value)

    on_exit(fn ->
      if original_value == nil do
        Application.delete_env(app, key)
      else
        Application.put_env(app, key, original_value)
      end
    end)
  end
end
