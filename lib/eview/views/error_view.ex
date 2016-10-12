defmodule EView.ErrorView do
  @doc """
  This render will be used by-default for non-existent routes. You can use it in your controller:

        conn |> render("404.json", error_description)
  """
  def render("404.json", error_type) when is_atom(error_type) or is_binary(error_type) do
    %{type: error_type}
  end

  def render("404.json", _assigns) do
    %{type: :not_found}
  end

  @doc """
  This render will be used by-default for internal errors. You can use it in your controller:

        conn |> render("500.json", error_description)
  """
  def render("500.json", error_type) when is_atom(error_type) or is_binary(error_type) do
    %{type: error_type}
  end

  def render("500.json", _assigns) do
    %{type: :internal_error}
  end
end
