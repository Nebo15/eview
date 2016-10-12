defmodule EView.ErrorView do
  def render("404.json", _assigns) do
    %{type: :not_found}
  end

  def render("500.json", _assigns) do
    %{type: :internal_error}
  end

  def template_not_found(_template, assigns) do
    render "500.json", assigns
  end
end
