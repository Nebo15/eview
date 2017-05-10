defmodule EView.ChangesetValidationsParserTest do
  use ExUnit.Case, async: true
  import Ecto.Changeset

  defmodule Post do
    use Ecto.Schema

    schema "posts" do
      field :title, :string, default: ""
      field :body
      field :uuid, :binary_id
      field :decimal, :decimal
      field :upvotes, :integer, default: 0
      field :topics, {:array, :string}
      field :phones, {:array, :map}
      field :uuids, {:array, Ecto.UUID}
      field :virtual, :string, virtual: true
      field :published_at, :naive_datetime
      field :metadata, :map
      field :email
    end
  end

  defmodule Blog do
    use Ecto.Schema

    schema "posts" do
      field :title, :string, default: ""
      embeds_many :posts, EView.ChangesetValidationsParserTest.Post
      embeds_one :post, EView.ChangesetValidationsParserTest.Post
    end
  end

  defp changeset(schema \\ %Post{}, params) do
    cast(schema, params, ~w(title body upvotes decimal topics phones uuids virtual email metadata))
  end

  defp blog_changeset(schema \\ %Blog{}, params) do
    schema
    |> cast(params, ~w(title))
    |> cast_embed(:posts, with: &changeset/2)
    |> cast_embed(:post, with: &changeset/2)
  end

  test "cast" do
    changeset = %{upvotes: "not_a_integer"} |> changeset()
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.upvotes",
        entry_type: "json_data_property",
        rules: [
          %{
            rule: :cast,
            params: [:integer]
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "query entry type" do
    changeset = %{upvotes: "not_a_integer"} |> changeset()
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.upvotes",
        entry_type: "query_parameter",
        rules: [
          %{
            rule: :cast,
            params: [:integer]
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.query.json", changeset)
  end

  test "cast list with UUID" do
    changeset = changeset(%Post{}, %{"uuids" => ["invalid"]})
    assert %{invalid: [
      %{
        entry: "$.uuids",
        rules: [
          %{
            rule: :cast,
            params: [:uuid]
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "cast list with phones" do
    changeset = changeset(%Post{}, %{"phones" => ["invalid"]})
    assert %{invalid: [
      %{
        entry: "$.phones",
        rules: [
          %{
            rule: :cast,
            params: [:maps_array]
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "cast list with phone" do
    changeset =
      %Blog{}
      |> cast(%{"post" => "invalid"}, ~w(title))
      |> cast_embed(:posts, with: &changeset/2)
      |> cast_embed(:post, with: &changeset/2)

    assert %{invalid: [
      %{
        entry: "$.post",
        rules: [
          %{
            rule: :cast,
            params: [:map]
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "cast list with strings" do
    changeset = changeset(%Post{}, %{"topics" => ["string", "string", :atom]})
    assert %{invalid: [
      %{
        entry: "$.topics",
        rules: [
          %{
            rule: :cast,
            params: [:strings_array]
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "cast embed" do
    changeset =
      %{posts: "not an array"}
      |> blog_changeset()
      |> validate_required(:title)

    assert %{invalid: [
      %{
        entry: "$.posts",
        rules: [
          %{
            rule: :cast,
            params: [:maps_array]
          }
        ]
      },
      %{
        entry: "$.title",
        rules: [
          %{
            rule: :required,
            params: []
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    changeset =
      %{posts: ["invalid type"]}
      |> blog_changeset()
      |> validate_required(:title)

    assert %{invalid: [
      %{
        entry: "$.posts",
        rules: [
          %{
            rule: :cast,
            params: [:maps_array]
          }
        ]
      },
      %{
        entry: "$.title",
        rules: [
          %{
            rule: :required,
            params: []
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    changeset =
      %{posts: [%{upvotes: 11}, %{upvotes: "not_a_integer"}], post: %{upvotes: "not_a_integer"}}
      |> blog_changeset()
      |> validate_required(:title)

    assert %{invalid: [
      %{
        entry: "$.post.upvotes",
        rules: [
          %{
            rule: :cast,
            params: [:integer]
          }
        ]
      },
      %{
        entry: "$.posts[1].upvotes",
        rules: [
          %{
            rule: :cast,
            params: [:integer]
          }
        ]
      },
      %{
        entry: "$.title",
        rules: [
          %{
            rule: :required,
            params: []
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "validate_required/2" do
    changeset = %{} |> changeset() |> validate_required(:title)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.title",
        rules: [
          %{
            rule: :required,
            params: []
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "validate_format/3" do
    changeset =
      %{"title" => "foobar"}
      |> changeset()
      |> validate_format(:title, ~r/@/)

    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.title",
        rules: [
          %{
            rule: :format,
            params: ["~r/@/"]
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "validate_inclusion/3" do
    changeset =
      %{"title" => "hello"}
      |> changeset()
      |> validate_inclusion(:title, ~w(world universe))
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.title",
        rules: [
          %{
            rule: :inclusion,
            params: ["world", "universe"]
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "validate_subset/3" do
    changeset =
      %{"topics" => ["cat", "laptop"]}
      |> changeset()
      |> validate_subset(:topics, ~w(cat dog))

    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.topics",
        rules: [
          %{
            rule: :subset,
            params: ["cat", "dog"]
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "validate_exclusion/3" do
    changeset =
      %{"title" => "world"}
      |> changeset()
      |> validate_exclusion(:title, ~w(world))
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.title",
        rules: [
          %{
            rule: :exclusion,
            params: ["world"]
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "validate_length/3 with string" do
    changeset =
      %{"title" => "world"}
      |> changeset()
      |> validate_length(:title, min: 6, max: 5, is: 3)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.title",
        rules: [
          %{
            rule: :length,
            params: %{min: 6, max: 5, is: 3}
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    changeset =
      %{"title" => "world"}
      |> changeset()
      |> validate_length(:title, min: 6)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.title",
        rules: [
          %{
            rule: :length,
            params: %{min: 6}
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    changeset =
      %{"title" => "world"}
      |> changeset()
      |> validate_length(:title, max: 4)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.title",
        rules: [
          %{
            rule: :length,
            params: %{max: 4}
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    changeset =
      %{"title" => "world"}
      |> changeset()
      |> validate_length(:title, is: 10)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.title",
        rules: [
          %{
            rule: :length,
            params: %{is: 10}
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "validate_length/3 with list" do
    changeset =
      %{"topics" => ["Politics", "Security"]}
      |> changeset()
      |> validate_length(:topics, min: 3, max: 3, is: 3)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.topics",
        rules: [
          %{
            rule: :length,
            params: %{min: 3, max: 3, is: 3}
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    changeset =
      %{"topics" => ["Politics", "Security"]}
      |> changeset()
      |> validate_length(:topics, min: 6, foo: true)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.topics",
        rules: [
          %{
            rule: :length,
            params: %{min: 6, foo: true}
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    changeset =
      %{"topics" => ["Politics", "Security", "Economy"]}
      |> changeset()
      |> validate_length(:topics, max: 2)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.topics",
        rules: [
          %{
            rule: :length,
            params: %{max: 2}
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    changeset =
      %{"topics" => ["Politics", "Security"]}
      |> changeset()
      |> validate_length(:topics, is: 10)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.topics",
        rules: [
          %{
            rule: :length,
            params: %{is: 10}
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "validate_number/3" do
    # Single error
    changeset =
      %{"upvotes" => -1}
      |> changeset()
      |> validate_number(:upvotes, greater_than: 0)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.upvotes",
        rules: [
          %{
            rule: :number,
            params: %{greater_than: 0}
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    # Multiple validations with multiple errors
    changeset =
      %{"upvotes" => 3}
      |> changeset()
      |> validate_number(:upvotes, greater_than: 100, less_than: 0)
    refute changeset.valid?
    assert %{invalid: [
      %{
        entry: "$.upvotes",
        rules: [
          %{
            rule: :number,
            params: %{greater_than: 100, less_than: 0}
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "validate_confirmation/3" do
    changeset =
      %{"title" => "title"}
      |> changeset()
      |> validate_confirmation(:title, required: true)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.title_confirmation",
        rules: [
          %{
            rule: :required,
            params: []
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    changeset =
      %{"title" => "title", "title_confirmation" => nil}
      |> changeset()
      |> validate_confirmation(:title)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.title_confirmation",
        rules: [
          %{
            rule: :confirmation,
            params: []
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    changeset =
      %{"title" => "title", "title_confirmation" => "not title"}
      |> changeset()
      |> validate_confirmation(:title)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.title_confirmation",
        rules: [
          %{
            rule: :confirmation,
            params: []
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    changeset =
      %{"title" => "title", "title_confirmation" => "not title"}
      |> changeset()
      |> validate_confirmation(:title, message: "doesn't match field below")
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.title_confirmation",
        rules: [
          %{
            rule: :confirmation,
            params: []
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    # With blank change
    changeset =
      %{"password" => "", "password_confirmation" => "password"}
      |> changeset()
      |> validate_confirmation(:password)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.password_confirmation",
        rules: [
          %{
            rule: :confirmation,
            params: []
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    # With missing change
    changeset =
      %{"password_confirmation" => "password"}
      |> changeset()
      |> validate_confirmation(:password)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.password_confirmation",
        rules: [
          %{
            rule: :confirmation,
            params: []
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "validate_acceptance/3" do
    changeset =
      %{"terms_of_service" => "false"}
      |> changeset()
      |> validate_acceptance(:terms_of_service)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.terms_of_service",
        rules: [
          %{
            rule: :acceptance,
            params: []
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    changeset =
      %{}
      |> changeset()
      |> validate_acceptance(:terms_of_service, message: "must be abided")
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.terms_of_service",
        rules: [
          %{
            rule: :acceptance,
            params: []
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "validate_email/3" do
    changeset =
      %{"email" => "email@example.com"}
      |> changeset()
      |> EView.Changeset.Validators.Email.validate_email(:email)
    assert changeset.valid?

    changeset =
      %{"email" => "plainaddress"}
      |> changeset()
      |> EView.Changeset.Validators.Email.validate_email(:email)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.email",
        rules: [
          %{
            rule: :email,
            params: [_],
            description: "is not a valid email"
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "validate_phone_number/3" do
    changeset =
      %{"virtual" => "+380631112233"}
      |> changeset()
      |> EView.Changeset.Validators.PhoneNumber.validate_phone_number(:virtual)
    assert changeset.valid?

    changeset =
      %{"virtual" => "not_a_number"}
      |> changeset()
      |> EView.Changeset.Validators.PhoneNumber.validate_phone_number(:virtual)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.virtual",
        rules: [
          %{
            rule: :phone_number,
            params: [_],
            description: "is not a valid phone number"
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "validate_card_number/3" do
    changeset =
      %{"virtual" => "5457000000000007"}
      |> changeset()
      |> EView.Changeset.Validators.CardNumber.validate_card_number(:virtual)
    assert changeset.valid?

    changeset =
      %{"virtual" => "5457000000000001"}
      |> changeset()
      |> EView.Changeset.Validators.CardNumber.validate_card_number(:virtual)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.virtual",
        rules: [
          %{
            rule: :card_number,
            params: [],
            description: "is not a valid card number"
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    changeset =
      %{"virtual" => "5457000000000001"}
      |> changeset()
      |> EView.Changeset.Validators.CardNumber.validate_card_number(:virtual,
                                    message: "is not a valid card number. We accept only: %{allowed_card_types}")
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.virtual",
        rules: [
          %{
            rule: :card_number,
            params: [],
            description: "is not a valid card number. We accept only: visa, master_card"
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "cast maps" do
    changeset =
      %{"metadata" => "{'upvotes': 'not_a_integer'}"}
      |> changeset()

    assert %{invalid: [
      %{
        entry: "$.metadata",
        rules: [
          %{
            rule: :cast,
            params: [:map]
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end

  test "validate_metadata/3" do
    changeset =
      %{"metadata" => %{
        "my_key": "meta_value",
        "int_key": 1337,
        "list_key": ["a", "b", "c"]
      }}
      |> changeset()
      |> EView.Changeset.Validators.Metadata.validate_metadata(:metadata)
    assert changeset.valid?

    changeset =
      %{"metadata" => "not_an_object"}
      |> changeset()
      |> EView.Changeset.Validators.Metadata.validate_metadata(:metadata)
    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.metadata",
        rules: [
          %{
            rule: :cast,
            params: [:map]
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)

    changeset =
      %{"metadata" => %{
        "lo" <> String.duplicate("o", 100) <> "ong_key" => "val",
        "foo" => String.duplicate("bar", 300),
        "list" => 1..200,
        "string_list" => ["a", String.duplicate("bar", 300)]
      }}
      |> changeset()
      |> EView.Changeset.Validators.Metadata.validate_metadata(:metadata)

    refute changeset.valid?

    assert %{invalid: [
      %{
        entry: "$.metadata.foo",
        rules: [
          %{
            description: "value should be up to 500 characters",
            rule: :length,
            params: %{max: 500}
          }
        ]
      },
      %{
        entry: "$.metadata.list",
        rules: [
          %{
            description: "is invalid",
            rule: :cast,
            params: [:integer, :float, :decimal, :string]
          }
        ]
      },
      %{
        entry: "$.metadata.lo" <> _,
        rules: [
          %{
            description: "key should be up to 100 characters",
            rule: :length,
            params: %{max: 100}
          }
        ]
      },
      %{
        entry: "$.metadata.string_list[1]" <> _,
        rules: [
          %{
            description: "list keys should be up to 100 characters",
            rule: :length,
            params: %{max: 100}
          }
        ]
      }
    ]} = EView.Views.ValidationError.render("422.json", changeset)
  end
end
