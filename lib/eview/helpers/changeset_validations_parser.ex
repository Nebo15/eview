if Code.ensure_loaded?(Ecto) do
  defmodule EView.Helpers.ChangesetValidationsParser do
    @moduledoc false
    # This module converts changeset to a error structure described in API Manifest.

    @entry_type "json_data_property"
    @jsonpath_root "$"
    @jsonpath_joiner "."

    def changeset_to_rules(%Ecto.Changeset{} = changeset, entry_type \\ @entry_type) do
      changeset
      |> Ecto.Changeset.traverse_errors(&construct_rule/3)
      |> Enum.flat_map(&errors_flatener(&1, @jsonpath_root, entry_type))
    end

    defp construct_rule(%Ecto.Changeset{validations: validations}, field, {message, opts}) do
      validation_name = opts[:validation]
      get_rule(
        field,
        validation_name,
        put_validation(validations, validation_name, field, opts),
        message,
        opts)
    end

    # Special case for cast validation that stores type in field that dont match validation name
    defp put_validation(validations, :cast, field, opts) do
      [{field, {:cast, opts[:type]}} | validations]
    end

    defp put_validation(validations, nil, field, opts) do
      [{field, {nil, opts[:type]}} | validations]
    end

    # Special case for metadata validator that can't modify to changeset validations
    defp put_validation(validations, :length, field, opts) do
      validation = Keyword.take(opts, [:min, :max, :is])
      [{field, {:length, validation}} | validations]
    end

    defp put_validation(validations, _, _field, _opts), do: validations

    defp get_rule(field, validation_name, validations, message, opts) do
      %{
        description: message |> get_rule_description(opts),
        rule: get_rule(opts),
        params: field |> reduce_rule_params(validation_name, validations) |> cast_rules_type()
      }
    end

    defp get_rule([validation: validation]), do: validation
    defp get_rule([_, validation: validation]), do: validation
    defp get_rule([validation, _]), do: validation
    defp get_rule([type: {validation, _incoming}]), do: validation

    defp get_rule_description(message, opts) do
      Enum.reduce(opts, message, fn
        # Lists
        {key, value}, acc when is_list(value) ->
          String.replace(acc, "%{#{key}}", Enum.join(value, ", "))

        {key, {:array, Ecto.UUID}}, acc ->
          String.replace(acc, "%{#{key}}", "uuid")

        {key, {:array, :map}}, acc ->
          String.replace(acc, "%{#{key}}", "array")

        # Everything else is a string
        {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end

    defp reduce_rule_params(field, validation_name, validations) do
      validations
      |> Keyword.get_values(field)
      |> Enum.reduce([], fn
        # Validation with keywords
        {^validation_name, [h | _] = keyword}, acc when is_tuple(h) ->
          keyword ++ acc

        # With list
        {^validation_name, list}, acc when is_list(list) ->
          list ++ acc

        # With regex pattern
        {^validation_name, %Regex{} = regex}, acc ->
          [inspect(regex) | acc]

        # Ecto.UUID rule
        {^validation_name, {:array, Ecto.UUID}}, acc ->
          [:uuid | acc]

        # Ecto {:array, :map} rule
        {^validation_name, {:array, :map}}, acc ->
          [:map | acc]

        # Or at least parseable
        {^validation_name, rule_description}, acc ->
          [rule_description | acc]

        # Skip rest
        _, acc ->
          acc
      end)
      |> Enum.uniq
    end

    defp cast_rules_type([h | _] = rules) when is_tuple(h),
      do: rules |> Enum.into(%{})
    defp cast_rules_type(rules),
      do: rules

    # Recursively flatten errors map
    defp errors_flatener({field, [%{rule: _}|_] = rules}, prefix, entry_type) when is_list(rules) do
      [%{
        entry_type: entry_type,
        entry: prefix <> @jsonpath_joiner <> to_string(field),
        rules: rules
      }]
    end

    defp errors_flatener({field, errors}, prefix, entry_type) when is_map(errors) do
      errors
      |> Enum.flat_map(&errors_flatener(&1, prefix <> @jsonpath_joiner <> to_string(field), entry_type))
    end

    defp errors_flatener({field, errors}, prefix, entry_type) when is_list(errors) do
      {acc, _} = errors
      |> Enum.reduce({[], 0}, fn inner_errors, {acc, i} ->
        inner_rules = inner_errors
        |> Enum.flat_map(&errors_flatener(
             &1,
             "#{prefix}#{@jsonpath_joiner}" <> to_string(field) <> "[#{i}]",
             entry_type
           ))

        {acc ++ inner_rules, i + 1}
      end)

      acc
    end
  end
end
