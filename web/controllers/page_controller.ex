defmodule Demo.PageController do
  @moduledoc """
  Sample controller for generated application.
  """

  use Demo.Web, :controller
  # use EView, :controller

  def index(conn, _params) do
    # dat = %Demo.SampleSchema{originator: "hello", loans_count: 123}

    conn
    |> put_status(200)
    |> render("page.json", %{
      data: %{
        hello: "Bob",
      },
      paging: %{
        limit: 50,
        cursors: %{
          starting_after: "MTAxNTExOTQ1MjAwNzI5NDE=",
          ending_before: "NDMyNzQyODI3OTQw"
        },
        has_more: true
      },
      sandbox: %{otp_code: "123"},
      urgent: %{balance: 300}
    })
  end
end
