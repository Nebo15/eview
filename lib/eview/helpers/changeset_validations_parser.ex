if Code.ensure_loaded?(Ecto) do
  defmodule EView.Helpers.ChangesetValidationsParser do
    @moduledoc false
    # This module converts changeset to a error structure described in API Manifest.

    @enty_type "json_data_property"
    @jsonpath_root "$"
    @jsonpath_joiner "."

    def changeset_to_rules(%Ecto.Changeset{} = changeset) do
      changeset
      |> Ecto.Changeset.traverse_errors(&construct_rule/3)
      |> Enum.flat_map(&errors_flatener(&1, @jsonpath_root))
    end

    defp construct_rule(%Ecto.Changeset{validations: validations}, field, {message, opts}) do
      validation_name = opts[:validation]

      # Special case for cast validation that stores type in field that dont match validation name
      validations = if validation_name == :cast,
          do: put_cast_validation(field, validations, opts),
        else: validations

      # Special case for metadata validator that can't modify to changeset validations
      validations = if validation_name == :length,
          do: put_length_validation(field, validations, opts),
        else: validations

      %{
        description: get_rule_description(message, opts),
        rule: opts[:validation],
        params: field |> reduce_rule_params(validation_name, validations) |> cast_rules_type()
      }
    end

    defp put_cast_validation(field, validations, opts) do
      [{field, {:cast, opts[:type]}} | validations]
    end

    defp put_length_validation(field, validations, opts) do
      validation = Keyword.take(opts, [:min, :max, :is])
      [{field, {:length, validation}} | validations]
    end

    defp get_rule_description(message, opts) do
      Enum.reduce(opts, message, fn
        # Lists
        {key, value}, acc when is_list(value) ->
          String.replace(acc, "%{#{key}}", Enum.join(value, ", "))

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
    defp errors_flatener({field, rules}, prefix) when is_list(rules) do
      [%{
        entry_type: @enty_type,
        entry: prefix <> @jsonpath_joiner <> to_string(field),
        rules: rules
      }]
    end

    defp errors_flatener({field, %{} = nested_errors}, prefix) do
      Enum.flat_map(nested_errors, &errors_flatener(&1, prefix <> @jsonpath_joiner <> to_string(field)))
    end
  end
end
