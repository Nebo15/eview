# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure for your application as:
#
#     config :eview, key: :value
#
# And access this configuration in your application as:
#
#     Application.get_env(:eview, :key)
#
# Or configure a 3rd-party app:
#
#     config :logger, level: :info
#
# Or read environment variables in runtime (!) as:
#
#     :var_name, "${ENV_VAR_NAME}"

config :eview,
  namespace: Demo,
  ecto_repos: []

# Configures the endpoint
config :eview, Demo.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "GJq0cIAxm5Egzg5lpPOibBooSTLWa3qfgoDGRsMpXDCjFkLK3uyTf4wICdyJ6W0Y",
  render_errors: [view: Demo.ErrorView, accepts: ~w(json)],
  http: [port: 4001],
  server: true

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]
