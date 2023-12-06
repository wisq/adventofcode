numbers =
  [
    ~w{one two three four five six seven eight nine} |> Enum.with_index(1),
    1..9 |> Enum.map(fn num -> {Integer.to_string(num), num} end)
  ]
  |> List.flatten()
  |> Map.new()

regex_numbers = Map.keys(numbers) |> Enum.join("|")
regex_body = ".*(#{regex_numbers})"

regex_first = Regex.compile!(regex_body, "U")
regex_last = Regex.compile!(regex_body)

IO.stream(:stdio, :line)
|> Stream.map(fn line ->
  [_, tens] = Regex.run(regex_first, line)
  [_, ones] = Regex.run(regex_last, line)
  tens = Map.fetch!(numbers, tens)
  ones = Map.fetch!(numbers, ones)
  "#{tens}#{ones}" |> String.to_integer()
end)
|> Enum.sum()
|> IO.inspect()
