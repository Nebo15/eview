defmodule Demo.PageView do
  @moduledoc """
  Sample view for Pages controller.
  """

  use Demo.Web, :view
  use EView, :view

  view("page.json", %{data: data} = assigns) do
    data
  end
end
