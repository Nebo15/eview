[:ecto, :postgrex, :cowboy, :httpoison, :jason, :phoenix, :timex, :jvalid, :timex_ecto]
|> Enum.map(&Application.ensure_all_started/1)

Demo.start()
ExUnit.start()
