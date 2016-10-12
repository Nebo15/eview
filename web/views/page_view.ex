defmodule Demo.PageView do
  @moduledoc """
  Sample view for Pages controller.
  """

  use Demo.Web, :view

  def render("page.json", %{data: data}) do
    data
  end
end
