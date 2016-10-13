defmodule Demo.PageView do
  @moduledoc false

  use Demo.Web, :view

  def render("page.json", %{data: data}) do
    data
  end
end
