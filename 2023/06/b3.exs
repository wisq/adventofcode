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

  fast_enough = fn charge_time ->
    distance = (duration - charge_time) * charge_time
    distance > record
  end

  [min_charge, max_charge] =
    [{"Minimum", 1..duration}, {"Maximum", duration..1}]
    |> Task.async_stream(fn {type, range} ->
      range
      |> Enum.find(fast_enough)
      |> IO.inspect(label: "#{type} charge time")
    end)
    |> Enum.map(fn {:ok, rval} -> rval end)

  min_charge..max_charge
  |> Range.size()
  |> IO.inspect(label: "Ways to win")
end)
|> elem(0)
|> IO.inspect(label: "Time")
