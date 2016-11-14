defmodule EView.Views.ValidationError do
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
          |> render(EView.Views.ValidationError, "422.json", changeset)
      end
  """
  if Code.ensure_loaded?(Ecto) do
    @doc """
    Use this render template whenever you want to return validation error. Currently is supports:
      * `Ecto.Changeset` errors (you can pass Schema that failed validation or changeset by itself);
      * `ex_json_schema` validation errors.
    """
    def render("422.json", %{changeset: changeset}) do
      render("422.json", changeset)
    end

    def render("422.json", %Ecto.Changeset{} = changeset) do
      %{
        type: :validation_failed,
        invalid: EView.Helpers.ChangesetValidationsParser.changeset_to_rules(changeset),
        message: "Validation failed. You can find validators description at our API Manifest: " <>
                 "http://docs.apimanifest.apiary.io/#introduction/interacting-with-api/errors."
      }
    end
  end

  if Code.ensure_loaded?(NExJsonSchema) do
    @doc """
    Render a JSON Schema validation error.
    """
    def render("422.json", %{schema: errors}) when is_list(errors) do
      errors = errors
      |> Enum.map(&map_schema_errors/1)

      %{
        type: :validation_failed,
        invalid: errors,
        message: "Validation failed. You can find validators description at our API Manifest: " <>
                 "http://docs.apimanifest.apiary.io/#introduction/interacting-with-api/errors."
      }
    end

    defp map_schema_errors({rule, path}) do
      %{
        entry_type: "json_data_property",
        entry: path,
        rules: [rule]
      }
    end
  end
end
