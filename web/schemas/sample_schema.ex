defmodule Demo.SampleSchema do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  schema "sample" do
    field :originator, :string
    field :loans_count, :integer
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:originator, :loans_count])
    |> validate_required([:originator, :loans_count])
  end
end
