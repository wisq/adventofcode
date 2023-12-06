IO.stream(:stdio, :line)
|> Enum.map(fn line ->
  [_, card_no | numbers] = Regex.run(~r/^Card \s*(\d+): ([\d\s]+) \| ([\d\s]+)$/, line)

  [winning, mine] =
    numbers
    |> Enum.map(fn nums ->
      nums
      |> String.split()
      |> Enum.map(&String.to_integer/1)
    end)

  mine
  |> Enum.reduce(0, fn num, score ->
    case num in winning do
      true -> max(score * 2, 1)
      false -> score
    end
  end)
  |> IO.inspect(label: "Card #{card_no}")
end)
|> Enum.sum()
|> IO.inspect(label: "Sum")
