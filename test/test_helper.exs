[:ecto, :postgrex, :cowboy, :httpoison, :poison, :phoenix, :timex, :jvalid, :timex_ecto, :phoenix_ecto]
|> Enum.map(&Application.ensure_all_started/1)
Demo.start()
ExUnit.start()
