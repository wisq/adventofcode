IO.stream(:stdio, :line)
|> Stream.map(fn line ->
  case Regex.run(~r/^\D*(\d)(?:.*(\d))?\D*$/, line) do
    [_, n] -> "#{n}#{n}"
    [_, n, m] -> "#{n}#{m}"
  end
  |> String.to_integer()
end)
|> Enum.sum()
|> IO.inspect()
