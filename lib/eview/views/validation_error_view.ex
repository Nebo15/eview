defmodule EView.ValidationErrorView do
  @doc """
  Use this render template whenever you want to return validation error. Currently is supports:
    * `Ecto.Changeset` errors (you can pass Schema that failed validation or changeset by itself);
    * `ex_json_schema` validation errors.
  """
  def render("422.json", %Ecto.Changeset{errors: _errors} = changeset) do
    errors = Ecto.Changeset.traverse_errors(changeset, fn
      err -> render_changeset_error(err)
    end)
    |> Enum.map(&render_validation_element/1)
    # IO.inspect errors

    %{
      type: :validation_failed,
      invalid: errors,
      message: "Validation failed. You can find validators description at our API Manifest: " <>
               "http://docs.apimanifest.apiary.io/#introduction/interacting-with-api/errors."
    }
  end

  def render("422.json", %{changeset: changeset}) do
    render("422.json", changeset)
  end

  defp render_changeset_error({message, opts}) do
    Enum.reduce opts, message, fn {k, v}, acc ->
      IO.inspect {k, v}
      String.replace(acc, "%{#{k}}", to_string(v))
    end
  end

  defp render_validation_element({field, rules}) do
    rules = rules
    |> Enum.map(&render_validation_rule/1)

    %{
      entry_type: "json_data_proprty",
      entry: "#/" <> to_string(field),
      rules: rules
    }
  end

  defp render_validation_rule("can't be blank"), do: %{rule: :required}
  defp render_validation_rule("is invalid"), do: %{rule: :invalid}
end
