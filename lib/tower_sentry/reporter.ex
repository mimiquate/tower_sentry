defmodule TowerSentry.Reporter do
  @behaviour Tower.Reporter

  @impl true
  def report_event(%Tower.Event{
        kind: :error,
        reason: exception,
        stacktrace: stacktrace,
        id: id,
        plug_conn: plug_conn,
        metadata: metadata
      }) do
    if enabled?() do
      Sentry.capture_exception(
        exception,
        stacktrace: stacktrace,
        request: request_data(plug_conn),
        extra: %{id: id, metadata: metadata}
      )
    else
      IO.puts("TowerSentry NOT enabled, ignoring...")
    end
  end

  def report_event(%Tower.Event{
        kind: :throw,
        reason: reason,
        stacktrace: stacktrace,
        id: id,
        plug_conn: plug_conn,
        metadata: metadata
      }) do
    if enabled?() do
      Sentry.capture_message(
        "(throw) #{reason}",
        stacktrace: stacktrace,
        level: :error,
        request: request_data(plug_conn),
        extra: %{id: id, metadata: metadata}
      )
    else
      IO.puts("TowerSentry NOT enabled, ignoring...")
    end
  end

  def report_event(%Tower.Event{
        kind: :exit,
        reason: reason,
        stacktrace: stacktrace,
        id: id,
        plug_conn: plug_conn,
        metadata: metadata
      }) do
    if enabled?() do
      Sentry.capture_message(
        "(exit) #{inspect(reason)}",
        stacktrace: stacktrace,
        level: :error,
        request: request_data(plug_conn),
        extra: %{id: id, metadata: metadata}
      )
    else
      IO.puts("TowerSentry NOT enabled, ignoring...")
    end
  end

  def report_event(%Tower.Event{
        kind: :message,
        level: level,
        reason: message,
        id: id,
        metadata: metadata
      }) do
    if enabled?() do
      if is_binary(message) do
        message
      else
        inspect(message)
      end
      # TODO: Include plug conn data if available
      |> Sentry.capture_message(level: level, extra: %{id: id, metadata: metadata})
    else
      IO.puts("Tower.Sentry NOT enabled, ignoring...")
    end
  end

  if Code.ensure_loaded?(Plug.Conn) do
    @reported_request_headers ["user-agent"]

    defp request_data(%Plug.Conn{} = conn) do
      %{
        method: conn.method,
        url: "#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}",
        headers: request_headers(conn)
      }
    end

    defp request_data(_), do: %{}

    defp request_headers(%Plug.Conn{} = conn) do
      conn.req_headers
      |> Enum.filter(fn {header_name, _header_value} ->
        String.downcase(header_name) in @reported_request_headers
      end)
      |> Enum.into(%{})
    end
  else
    defp request_data(_), do: %{}
  end

  defp enabled? do
    Sentry.Config.dsn()
  end
end
