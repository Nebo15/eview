# Demo

In [Nebo #15](http://nebo15.com) we have our own [API design manifest](http://docs.apimanifest.apiary.io/), and we trying to follow it.

This package extracts all common patterns and utilities, to remove boilerplate from business-logic services.

## Installation

The package can be installed as:

  1. Add `eview` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:eview, "~> 0.10.6"}]
    end
    ```

  2. Ensure `eview` is started before your application:

    ```elixir
    def application do
      [applications: [:eview]]
    end
    ```

The docs can be found at [https://hexdocs.pm/eview](https://hexdocs.pm/eview).

