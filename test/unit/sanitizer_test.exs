defmodule EView.Helpers.SanitizerTest do
  use ExUnit.Case, async: true

  alias EView.Helpers.Sanitizer

  test "turns tuples into lists" do
    assert [:hello, :world] = Sanitizer.sanitize({:hello, :world})
  end

  test "turns map into sanitized maps" do
    assert %{a: [1, 2]} = Sanitizer.sanitize(%{a: {1, 2}})
  end

  test "turns lists into sanitized lists" do
    assert [[1, 2], [3, 4]] = Sanitizer.sanitize([{1, 2}, {3, 4}])
  end
end
