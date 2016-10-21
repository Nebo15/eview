defmodule Ecto.Changeset.PhoneNumberValidator do
  @moduledoc """
  This helper validates phone numbers in international format (with `+:country_code`).
  """
  import Ecto.Changeset

  @phone_regex ~r/^\+[0-9]{9,16}$/

  def validate_phone_number(changeset, field, opts \\ []) do
    validate_change changeset, field, {:phone_number, @phone_regex}, fn _, value ->
      if value =~ @phone_regex,
          do: [],
        else: [{field, {message(opts, "is not a valid phone number"), [validation: :phone_number]}}]
    end
  end

  defp message(opts, key \\ :message, default) do
    Keyword.get(opts, key, default)
  end
end
