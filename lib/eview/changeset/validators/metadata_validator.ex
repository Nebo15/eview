if Code.ensure_loaded?(Ecto) do
  defmodule EView.Changeset.Validators.Metadata do
    @moduledoc """
    This helper validates metadata corresponding to
    [API Manifest](http://docs.apimanifest.apiary.io/#introduction/optional-features/metadata).
    """
    import Ecto.Changeset

    @max_key_length 100
    @max_value_length 500
    @max_list_length 25
    @max_list_value_length 100

    @jsonpath_joiner "."

    def validate_metadata(changeset, field, opts \\ []) do
      validate_change changeset, field, :metadata, fn _, value ->
        get_metadata_errors(field, value, opts)
      end
    end

    defp get_metadata_errors(field, metadata, _opts) when is_map(metadata) do
      Enum.reduce(metadata, [], &field_validation_reducer(field, &1, &2))
    end

    defp get_metadata_errors(field, _, opts) do
      [{field, {message(opts, "is not a valid metadata object"), [validation: :metadata]}}]
    end

    # Convert atom keys to strings
    defp field_validation_reducer(parent, {key, val}, acc) when is_atom(key) do
      field_validation_reducer(parent, {to_string(key), val}, acc)
    end

    # Check max length of key
    defp field_validation_reducer(parent, {key, _}, acc) when is_binary(key) and byte_size(key) > @max_key_length do
      [{field_path(parent, key),
       {"key should be up to %{max} characters", [validation: :length, max: @max_key_length]}}
      | acc]
    end

    # Check binary value max length
    defp field_validation_reducer(parent, {key, val}, acc) when is_binary(val) and byte_size(val) > @max_value_length do
      [{field_path(parent, key),
       {"value should be up to %{max} characters", [validation: :length, max: @max_value_length]}}
      | acc]
    end

    # Check list values
    defp field_validation_reducer(parent, {key, list}, acc) when is_list(list) and length(list) > @max_list_length do
      [{field_path(parent, key),
       {"lists should be up to %{max} elements", [validation: :length, max: @max_list_length]}}
      | acc]
    end

    # Check list elements length
    defp field_validation_reducer(parent, {key, list}, acc) when is_list(list) do
      {errors, _} = Enum.reduce(list, {[], 0}, fn
        %Decimal{}, {el_acc, i} ->
          {el_acc, i + 1}
        elem, {el_acc, i} when is_float(elem) or is_number(elem) ->
          {el_acc, i + 1}
        elem, {el_acc, i} when is_binary(elem) and byte_size(elem) <= @max_list_value_length ->
          {el_acc, i + 1}
        elem, {el_acc, i} when is_binary(elem) and byte_size(elem) > @max_list_value_length ->
          {[{join_atoms(field_path(parent, key), "[#{i}]"),
            {"list keys should be up to %{max} characters", [validation: :length, max: @max_key_length]}}
          | el_acc], i + 1}
        _, {el_acc, i} ->
          {[{field_path(parent, key),
            {"one of keys is invalid", [validation: :cast, type: [:integer, :float, :decimal, :string]]}}
          | el_acc], i + 1}
      end)

      errors ++ acc
    end

    # Pass integers, decimals and floats
    defp field_validation_reducer(_parent, {_, number}, acc) when is_float(number) or is_integer(number), do: acc
    defp field_validation_reducer(_parent, {_, %Decimal{}}, acc), do: acc

    # Pass valid binary keys and values
    defp field_validation_reducer(_parent, {key, val}, acc)
      when is_binary(key) and byte_size(key) <= @max_key_length
       and is_binary(val) and byte_size(val) <= @max_value_length do
      acc
    end

    # Everything else is an error
    defp field_validation_reducer(parent, {key, _val}, acc) do
      [{field_path(parent, key),
       {"is invalid", [validation: :cast, type: [:integer, :float, :decimal, :string]]}}
      | acc]
    end

    # Join atom in JSON Path style
    defp field_path(parent, child) do
      String.to_atom(to_string(parent) <> @jsonpath_joiner <> to_string(child))
    end

    # Join strings or atoms and return a string
    defp join_atoms(prefix, sufix) do
      String.to_atom(to_string(prefix) <> to_string(sufix))
    end

    # Extract message from options
    defp message(opts, key \\ :message, default) do
      Keyword.get(opts, key, default)
    end
  end
end
