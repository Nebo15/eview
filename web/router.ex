defmodule Demo.Router do
  @moduledoc false

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
