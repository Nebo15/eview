defmodule EView.ValidationErrorView do
  @moduledoc """
  This module provides renders that can be used whenever you want to show validation error.

  # Example:

      changeset = %SampleSchema{}
      |> SampleSchema.changeset(params)

      case changeset.valid? do
        true ->
          conn
          |> put_status(200)
          |> render("page.json", map_keys_to_atom(params))
        _ ->
          conn
          |> put_status(422)
          |> render(EView.ValidationErrorView, "422.json", changeset)
      end
  """

  @doc """
  Use this render template whenever you want to return validation error. Currently is supports:
    * `Ecto.Changeset` errors (you can pass Schema that failed validation or changeset by itself);
    * `ex_json_schema` validation errors.
  """
  def render("422.json", %{changeset: changeset}) do
    render("422.json", changeset)
  end

  def render("422.json", %Ecto.Changeset{errors: _errors} = changeset) do
    errors = changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
        %{
          rule: msg,
          params: opts
        }
    end)
    |> Enum.flat_map(&map_changeset_errors(&1, "#"))

    %{
      type: :validation_failed,
      invalid: errors,
      message: "Validation failed. You can find validators description at our API Manifest: " <>
               "http://docs.apimanifest.apiary.io/#introduction/interacting-with-api/errors."
    }
  end

  # JSON Schema
  def render("422.json", %{errors: errors}) when is_list(errors) do
    errors = errors
    |> Enum.map(&map_schema_errors/1)

    %{
      type: :validation_failed,
      invalid: errors,
      message: "Validation failed. You can find validators description at our API Manifest: " <>
               "http://docs.apimanifest.apiary.io/#introduction/interacting-with-api/errors."
    }
  end

  defp map_changeset_errors({field, rules}, prefix) when is_list(rules) do
    [
      %{
        entry_type: "json_data_proprty",
        entry: prefix <> "/" <> to_string(field),
        rules: map_rule_names(rules)
      }
    ]
  end

  defp map_changeset_errors({field, %{} = nested_errors}, prefix) do
    nested_errors
    |> Enum.flat_map(&map_changeset_errors(&1, prefix <> "/" <> to_string(field)))
  end

  defp map_rule_names(rules) when is_list(rules) do
    rules
    |> Enum.map(fn %{params: params, rule: rule} -> %{params: params, rule: get_rule_name(rule)} end)
  end

  defp map_schema_errors({rule, path}) do
    %{
      entry_type: "json_data_proprty",
      entry: path,
      rules: [%{rule: get_rule_name(rule)}]
    }
  end

  defp get_rule_name("can't be blank"), do: :required
  defp get_rule_name("is invalid"), do: :invalid
  defp get_rule_name(msg), do: msg
end
