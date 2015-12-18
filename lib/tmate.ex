defmodule Tmate do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    Application.put_env(:phoenix, :serve_endpoints, true, persistent: true)

    {:ok, daemon_options} = Application.fetch_env(:tmate, :daemon)
    {:ok, websocket_options} = Application.fetch_env(:tmate, :websocket)

    cowboy_opts = [env: [dispatch: Tmate.WebSocket.cowboy_dispatch], compress: true]

    children = [
      :ranch.child_spec(:daemon_tcp, 3, :ranch_tcp, daemon_options,
                        Tmate.DaemonTcp, []),
      :ranch.child_spec(:websocket_tcp, 3, websocket_options[:listener], websocket_options[:ranch_opts],
                        :cowboy_protocol, cowboy_opts),
      worker(Tmate.SessionRegistry, [[name: Tmate.SessionRegistry]]),
    ]

    Supervisor.start_link(children, [strategy: :one_for_one, name: Tmate.Supervisor])
  end
end
