IO.read(:stdio, :eof)
|> String.trim()
|> String.split("\n")
|> Enum.map(fn line ->
  line
  |> String.split()
  |> Enum.drop(1)
  |> Enum.map(&String.to_integer/1)
end)
|> Enum.zip()
|> Enum.map(fn {duration, record} ->
  1..duration
  |> Enum.count(fn charge_time ->
    distance = (duration - charge_time) * charge_time
    distance > record
  end)
end)
|> IO.inspect(label: "Ways to win each race")
|> Enum.product()
|> IO.inspect(label: "Error margin")
