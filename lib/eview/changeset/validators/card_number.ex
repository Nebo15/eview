if Code.ensure_loaded?(Ecto) and Code.ensure_loaded?(CreditCard) do
  defmodule EView.Changeset.Validators.CardNumber do
    @moduledoc """
    This helper validates card number by luhn algorithm.
    """
    import Ecto.Changeset

    @allowed_card_types [:visa, :master_card]

    def validate_card_number(changeset, field, opts \\ []) do
      allowed_card_types = opts[:allowed_card_types] || @allowed_card_types

      validate_change(changeset, field, :credit_card, fn _, value ->
        if CreditCard.valid?(value, %{allowed_card_types: allowed_card_types}),
          do: [],
          else: [
            {field,
             {message(opts, "is not a valid card number"),
              [validation: :card_number, allowed_card_types: allowed_card_types]}}
          ]
      end)
    end

    defp message(opts, key \\ :message, default) do
      Keyword.get(opts, key, default)
    end
  end
end
