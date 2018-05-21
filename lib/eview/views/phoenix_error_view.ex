defmodule EView.Views.PhoenixError do
  @moduledoc """
  Error view that can be used in Phoenix:

      config :myapp, MyApp.Endpoint,
        render_errors: [view: EView.Views.PhoenixError, accepts: ~w(json)]
  """

  # In some cases phoenix will drop `register_before_send` functions,
  # and we need to wrap body instantly, without waiting for EView plug.
  @phoenix_throwing_templates ["409.json", "413.json", "415.json"]
  def render(template, assigns) when template in @phoenix_throwing_templates do
    template
    |> render_template(assigns)
    |> EView.Renders.Root.render(assigns[:conn])
  end

  def render(template, assigns) do
    template
    |> render_template(assigns)
  end

  defp render_template(template, assigns) do
    template
    |> EView.Views.Error.render(assigns)
  end

  # In case no render clause matches or no
  # template is found, let's render it as 500
  def template_not_found(_template, assigns) do
    render("500.json", assigns)
  end
end
