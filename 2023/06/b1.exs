:timer.tc(fn ->
  [duration, record] =
    IO.read(:stdio, :eof)
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(fn line ->
      [_, numbers] = line |> String.split(":", parts: 2)

      numbers
      |> String.replace(~r/\s+/, "")
      |> String.to_integer()
    end)

  1..duration
  |> Enum.count(fn charge_time ->
    distance = (duration - charge_time) * charge_time
    distance > record
  end)
  |> IO.inspect(label: "Ways to win")
end)
|> elem(0)
|> IO.inspect(label: "Time")
