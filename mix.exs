defmodule EView.Mixfile do
  use Mix.Project

  @version "0.1.1"

  def project do
    [app: :eview,
     description: "Plug that converts response to Nebo #15 API spec format.",
     package: package,
     version: @version,
     elixir: "~> 1.3",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps(),
     test_coverage: [tool: ExCoveralls],
     preferred_cli_env: [coveralls: :test],
     docs: [source_ref: "v#\{@version\}", main: "readme", extras: ["README.md"]]]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger],
     included_applications: [:ecto, :poison, :plug]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # To depend on another app inside the umbrella:
  #
  #   {:myapp, in_umbrella: true}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:plug, "~> 1.2"},
     {:poison, "~> 2.0"},
     {:ecto, github: "elixir-ecto/ecto", optional: true, override: true}, # TODO: Update when Ecto will release v2.1
     {:credit_card, "~> 1.0", optional: true},
     {:ex_json_schema, "~> 0.5.1", only: [:dev, :test]},
     {:postgrex, "~> 0.12", only: [:dev, :test]},
     {:cowboy, "~> 1.0", only: [:dev, :test]},
     {:httpoison, "~> 0.9.2", only: [:dev, :test]},
     {:phoenix, "~> 1.2", only: [:dev, :test]},
     {:phoenix_ecto, "3.1.0-rc.0", only: [:dev, :test]}, # TODO: Update when Ecto will release v2.1
     {:ex_doc, ">= 0.0.0", only: [:dev, :test]},
     {:excoveralls, "~> 0.5", only: [:dev, :test]},
     {:dogma, "> 0.1.0", only: [:dev, :test]},
     {:credo, ">= 0.4.8", only: [:dev, :test]}]
  end

  # Settings for publishing in Hex package manager:
  defp package do
    [contributors: ["Nebo #15"],
     maintainers: ["Nebo #15"],
     licenses: ["LISENSE.md"],
     links: %{github: "https://github.com/Nebo15/eview"},
     files: ~w(lib LICENSE.md mix.exs README.md)]
  end
end
