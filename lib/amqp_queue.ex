defmodule AMQPQueue do
  use Application
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Load workers from application config
    children = for {args, i} <- Enum.with_index(Application.get_env(:queue, :workers, [])) do
      worker(AMQPQueue.Worker, args, id: "worker_" <> to_string(i))
    end

    opts = [strategy: :one_for_one, name: AMQPQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
