defmodule Demo do
  @moduledoc false

  def start do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Demo.Endpoint, []),
    ]

    opts = [strategy: :one_for_one, name: Demo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
