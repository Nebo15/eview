defmodule Demo do
  @moduledoc """
  Entrypoint of Demo application. It's only used in EView tests and as demo use-case.
  """

  def start do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(Demo.Endpoint, []),
    ]

    opts = [strategy: :one_for_one, name: Demo.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
