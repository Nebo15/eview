defmodule EView.Helpers.Sanitizer do
  @moduledoc false

  def sanitize(term) when is_list(term) do
    for item <- term, into: [], do: sanitize(item)
  end

  def sanitize(term) when is_map(term) do
    for {key, value} <- term, into: %{}, do: {key, sanitize(value)}
  end

  def sanitize(term) when is_tuple(term) do
    term
    |> Tuple.to_list
    |> sanitize()
  end

  def sanitize(term), do: term
end
