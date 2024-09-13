defmodule TowerSentry.Sentry.Event do
  @moduledoc false

  def from_tower_event(%Tower.Event{
        kind: :error,
        reason: exception,
        stacktrace: stacktrace,
        id: id,
        plug_conn: plug_conn,
        metadata: metadata
      }) do
    put_environment_name()

    Sentry.Event.create_event(
      exception: exception,
      stacktrace: stacktrace,
      request: request_data(plug_conn),
      extra: %{id: id, metadata: metadata}
    )
  end

  def from_tower_event(%Tower.Event{
        kind: :throw,
        reason: reason,
        stacktrace: stacktrace,
        id: id,
        plug_conn: plug_conn,
        metadata: metadata
      }) do
    put_environment_name()

    Sentry.Event.create_event(
      message: "(throw) #{reason}",
      stacktrace: stacktrace,
      level: :error,
      request: request_data(plug_conn),
      extra: %{id: id, metadata: metadata}
    )
  end

  def from_tower_event(%Tower.Event{
        kind: :exit,
        reason: reason,
        stacktrace: stacktrace,
        id: id,
        plug_conn: plug_conn,
        metadata: metadata
      }) do
    put_environment_name()

    Sentry.Event.create_event(
      message: "(exit) #{inspect(reason)}",
      stacktrace: stacktrace,
      level: :error,
      request: request_data(plug_conn),
      extra: %{id: id, metadata: metadata}
    )
  end

  def from_tower_event(%Tower.Event{
        kind: :message,
        level: level,
        reason: message,
        id: id,
        metadata: metadata
      }) do
    put_environment_name()

    # TODO: Include plug conn data if available
    Sentry.Event.create_event(
      message:
        if is_binary(message) do
          message
        else
          inspect(message)
        end,
      level: level,
      extra: %{id: id, metadata: metadata}
    )
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

  defp put_environment_name do
    Sentry.put_config(
      :environment_name,
      Application.fetch_env!(:tower_sentry, :environment_name)
    )
  end
end
