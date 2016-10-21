defmodule Ecto.Changeset.EmailValidator do
  @moduledoc """
  This helper validates emails by complex regex pattern.
  """
  import Ecto.Changeset

  @email_regex Regex.compile!(~S((?:[a-z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+\/=?^_`{|}~-]+\)*|") <>
               ~S((?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f]\)*"\)) <>
               ~S(@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9]\)?\.\)+[a-z0-9](?:[a-z0-9-]*[a-z0-9]\)?) <>
               ~S(|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?\)\.\){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?) <>
               ~S(|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]) <>
               ~S(|\\[\x01-\x09\x0b\x0c\x0e-\x7f]\)+\)\]\)))

  def validate_email(changeset, field, opts \\ []) do
    validate_change changeset, field, {:email, @email_regex}, fn _, value ->
      if value =~ @email_regex, do: [], else: [{field, {message(opts, "is not a valid email"), [validation: :email]}}]
    end
  end

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end
end
