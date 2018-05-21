defmodule EViewAcceptanceTest do
  use EView.AcceptanceCase,
    async: true,
    otp_app: :eview,
    endpoint: Demo.Endpoint,
    headers: [{"x-request-id", "my_request_id_000000"}, {"x-idempotency-key", "TestIdempotencyKey"}]

  use Plug.Test

  test "renders meta and data objects" do
    assert %{
             "meta" => %{
               "code" => 200,
               "request_id" => "my_request_id_000000",
               "idempotency_key" => "TestIdempotencyKey",
               "type" => "object",
               "url" => "http://localhost:4001/page"
             },
             "data" => %{
               "hello" => "Bob"
             }
           } =
             "page"
             |> post!(%{
               data: %{
                 hello: "Bob"
               }
             })
             |> get_body
             |> refute_key(:urgent)
             |> refute_key(:paging)
             |> refute_key(:sandbox)
  end

  test "overrides object type" do
    assert %{
             "data" => %{
               "type" => "mytype"
             }
           } =
             "page"
             |> post!(%{
               data: %{
                 type: "mytype",
                 hello: "Bob"
               }
             })
             |> get_body
  end

  test "meta code is http status" do
    assert %{
             "meta" => %{
               "code" => 401
             }
           } =
             "page"
             |> post!(%{
               data: %{
                 hello: "Bob"
               },
               status: 401
             })
             |> get_body
             |> refute_key(:urgent)
             |> refute_key(:paging)
             |> refute_key(:sandbox)
  end

  test "skips paging for objects" do
    "page"
    |> post!(%{
      data: %{
        hello: "Bob"
      },
      paging: %{
        limit: 50,
        cursors: %{
          starting_after: "MTAxNTExOTQ1MjAwNzI5NDE=",
          ending_before: "NDMyNzQyODI3OTQw"
        },
        has_more: true
      }
    })
    |> get_body
    |> refute_key(:paging)
  end

  test "renders sandbox data" do
    assert %{
             "sandbox" => %{
               "otp_code" => "123"
             }
           } =
             "page"
             |> post!(%{
               data: %{
                 hello: "Bob"
               },
               sandbox: %{
                 otp_code: "123"
               },
               env: "test"
             })
             |> get_body

    "page"
    |> post!(%{
      data: %{
        hello: "Bob"
      },
      sandbox: %{
        otp_code: "123"
      },
      env: "test"
    })
    |> get_body
    |> refute_key(:sandbox)
  end

  test "renders urgent data" do
    assert %{
             "urgent" => %{
               "balance" => 100
             }
           } =
             "page"
             |> post!(%{
               data: %{
                 hello: "Bob"
               },
               urgent: %{
                 balance: 100
               },
               env: "test"
             })
             |> get_body
  end

  test "renders list" do
    assert %{
             "meta" => %{
               "code" => 200,
               "request_id" => "my_request_id_000000",
               "idempotency_key" => "TestIdempotencyKey",
               "type" => "list",
               "url" => "http://localhost:4001/page"
             },
             "data" => [
               %{
                 "hello" => "Bob"
               }
             ]
           } =
             "page"
             |> post!(%{
               data: [
                 %{
                   hello: "Bob"
                 }
               ]
             })
             |> get_body
             |> refute_key(:urgent)
             |> refute_key(:paging)
             |> refute_key(:sandbox)
  end

  test "renders errors" do
    assert %{
             "meta" => %{
               "code" => 422,
               "request_id" => "my_request_id_000000",
               "idempotency_key" => "TestIdempotencyKey",
               "type" => "object",
               "url" => "http://localhost:4001/page"
             },
             "error" => %{
               "type" => "invalid_data"
             }
           } =
             "page"
             |> post!(%{
               status: 422,
               data: %{
                 type: "invalid_data"
               }
             })
             |> get_body
             |> refute_key(:urgent)
             |> refute_key(:paging)
             |> refute_key(:sandbox)
  end

  test "renders 404 error" do
    assert %{
             "meta" => %{
               "code" => 404,
               "type" => "object",
               "url" => "http://localhost:4001/not_found"
             },
             "error" => %{
               "type" => "not_found"
             }
           } =
             "not_found"
             |> post!(%{
               data: %{
                 type: "invalid_data"
               }
             })
             |> get_body
             |> refute_key(:urgent)
             |> refute_key(:paging)
             |> refute_key(:sandbox)
  end

  test "renders 500 error" do
    assert %{
             "meta" => %{
               "code" => 500,
               "type" => "object",
               "url" => "http://localhost:4001/page"
             },
             "error" => %{
               "type" => "internal_error"
             }
           } =
             "page"
             |> post!(%{
               data: %{
                 type: "invalid_data"
               },
               status: "not_boolean"
             })
             |> get_body
             |> refute_key(:urgent)
             |> refute_key(:paging)
             |> refute_key(:sandbox)
  end

  test "renders invalid content-type error" do
    assert %{
             "meta" => %{
               "code" => 415,
               "type" => "object",
               "url" => "http://localhost:4001/page"
             },
             "error" => %{
               "invalid" => [
                 %{
                   "entry_type" => "header",
                   "entry" => "Content-Type"
                 }
               ],
               "message" =>
                 "Invalid Content-Type header. Try to set 'Content-Type: application/json' header: " <>
                   "http://docs.apimanifest.apiary.io/#introduction/interacting-with-api/content-type.",
               "type" => "content_type_invalid"
             }
           } =
             "page"
             |> post!(
               %{
                 data: %{
                   type: "invalid_data"
                 }
               },
               [{"content-type", "application/unknown"}]
             )
             |> get_body
             |> refute_key(:urgent)
             |> refute_key(:paging)
             |> refute_key(:sandbox)
  end

  test "renders changeset validation errors" do
    assert %{
             "meta" => %{
               "code" => 422,
               "type" => "object",
               "url" => "http://localhost:4001/page_via_changeset"
             },
             "error" => %{
               "invalid" => [
                 %{
                   "entry" => "$.loans_count",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{"rule" => "required"}
                   ]
                 },
                 %{
                   "entry" => "$.originator",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "rule" => "required"
                     }
                   ]
                 }
               ],
               "message" =>
                 "Validation failed. You can find validators description at our API Manifest: " <>
                   "http://docs.apimanifest.apiary.io/#introduction/interacting-with-api/errors.",
               "type" => "validation_failed"
             }
           } =
             "page_via_changeset"
             |> post!(%{
               data: %{
                 type: "invalid_data"
               },
               status: "not_boolean"
             })
             |> get_body
             |> refute_key(:urgent)
             |> refute_key(:paging)
             |> refute_key(:sandbox)
  end

  test "renders json schema validation errors" do
    assert %{
             "meta" => %{
               "code" => 422,
               "type" => "object",
               "url" => "http://localhost:4001/page_via_schema"
             },
             "error" => %{
               "invalid" => [
                 %{
                   "entry" => "$.originator",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "value is not allowed in enum",
                       "params" => ["a", "b"],
                       "rule" => "inclusion"
                     }
                   ]
                 }
               ],
               "message" =>
                 "Validation failed. You can find validators description at our API Manifest: " <>
                   "http://docs.apimanifest.apiary.io/#introduction/interacting-with-api/errors.",
               "type" => "validation_failed"
             }
           } =
             "page_via_schema"
             |> post!(%{
               data: %{
                 originator: "me"
               },
               status: "not_boolean"
             })
             |> get_body
             |> refute_key(:urgent)
             |> refute_key(:paging)
             |> refute_key(:sandbox)
  end

  defp refute_key(map, elem) when is_map(map) do
    refute elem in Map.keys(map)

    map
  end
end
