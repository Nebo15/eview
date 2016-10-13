defmodule Demo.Router do
  @moduledoc """
  The router provides a set of macros for generating routes
  that dispatch to specific controllers and actions.
  Those macros are named after HTTP verbs.

  More info at: https://hexdocs.pm/phoenix/Phoenix.Router.html
  """

  use Demo.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :put_secure_browser_headers

    # You can allow JSONP requests by uncommenting this line:
    # plug :allow_jsonp
  end

  scope "/", Demo do
    pipe_through :api

    post "/page", PageController, :create
    post "/page_via_changeset", PageController, :validate_changeset
    post "/page_via_schema", PageController, :validate_schema
  end
end
