IO.stream(:stdio, :line)
|> Enum.map(fn line ->
  [_ | numbers] = Regex.run(~r/^Card \s*\d+: ([\d\s]+) \| ([\d\s]+)$/, line)

  [winning, mine] =
    numbers
    |> Enum.map(fn nums ->
      nums
      |> String.split()
      |> Enum.map(&String.to_integer/1)
    end)

  mine |> Enum.count(&(&1 in winning))
end)
|> Enum.reverse()
|> Enum.reduce([], fn wins, acc ->
  count = 1 + (Enum.take(acc, wins) |> Enum.sum())
  [count | acc]
end)
|> IO.inspect(label: "Acc")
|> Enum.sum()
|> IO.inspect(label: "Total")
