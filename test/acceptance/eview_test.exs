defmodule EViewAcceptanceTest do
  use EView.AcceptanceCase, async: true
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
        "type" => "page",
        "hello" => "Bob"
      }
    } = post!("page", %{
      data: %{
        hello: "Bob",
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
      },
    } = post!("page", %{
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
    } = post!("page", %{
      data: %{
        hello: "Bob",
      },
      status: 401
    })
    |> get_body
    |> refute_key(:urgent)
    |> refute_key(:paging)
    |> refute_key(:sandbox)
  end

  test "skips paging for objects" do
    post!("page", %{
      data: %{
        hello: "Bob",
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
      },
    } = post!("page", %{
      data: %{
        hello: "Bob",
      },
      sandbox: %{
        otp_code: "123"
      },
      env: "test"
    })
    |> get_body

    post!("page", %{
      data: %{
        hello: "Bob",
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
      },
    } = post!("page", %{
      data: %{
        hello: "Bob",
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
      "data" => [%{
        "hello" => "Bob"
      }]
    } = post!("page", %{
      data: [%{
        hello: "Bob",
      }]
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
    } = post!("page", %{
      status: 422,
      data: %{
        type: "invalid_data",
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
    } = post!("not_found", %{
      data: %{
        type: "invalid_data",
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
    } = post!("page", %{
      data: %{
        type: "invalid_data",
      },
      status: "not_boolean"
    })
    |> get_body
    |> refute_key(:urgent)
    |> refute_key(:paging)
    |> refute_key(:sandbox)
  end

  test "renders validation errors" do
    assert %{
      "meta" => %{
        "code" => 422,
        "type" => "object",
        "url" => "http://localhost:4001/page_via_schema"
      },
      "error" => %{
        "invalid" => [
          %{
            "entry" => "#/loans_count",
            "entry_type" => "json_data_proprty",
            "rules" => [
              %{"rule" => "required"}
            ]
          },
          %{
            "entry" => "#/originator",
            "entry_type" => "json_data_proprty",
            "rules" => [
              %{
                "rule" => "required"
              }
            ]
          }
        ],
        "message" => "Validation failed. You can find validators description at our API Manifest: http://docs.apimanifest.apiary.io/#introduction/interacting-with-api/errors.",
        "type" => "validation_failed"
      }
    } = post!("page_via_schema", %{
      data: %{
        type: "invalid_data",
      },
      status: "not_boolean"
    })
    |> get_body
    |> refute_key(:urgent)
    |> refute_key(:paging)
    |> refute_key(:sandbox)
  end

  defp get_body(map) do
    map
    |> Map.get(:body)
  end

  defp refute_key(map, elem) when is_map(map) do
    refute elem in Map.keys(map)

    map
  end
end
