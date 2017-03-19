defmodule Demo.Endpoint do
  @moduledoc false
  use Phoenix.Endpoint, otp_app: :eview

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug Phoenix.CodeReloader
  end

  plug EView
  plug EView.Plugs.Idempotency

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Poison

  plug Plug.MethodOverride
  plug Plug.Head

  plug Demo.Router
end
