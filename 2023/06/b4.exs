defmodule BinarySearch do
  def search(fail_time, pass_time, check_fn) do
    if abs(fail_time - pass_time) <= 1 do
      pass_time
    else
      mid_time = midpoint(fail_time, pass_time)

      case check_fn.(mid_time) do
        true -> search(fail_time, mid_time, check_fn)
        false -> search(mid_time, pass_time, check_fn)
      end
    end
  end

  def midpoint(t1, t2) when t1 < t2, do: t1 + div(t2 - t1, 2)
  def midpoint(t2, t1) when t1 < t2, do: t1 + div(t2 - t1, 2)
end

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
    [{"Minimum", 1, div(duration, 2)}, {"Maximum", duration, div(duration, 2)}]
    |> Task.async_stream(fn {type, fail_time, pass_time} ->
      BinarySearch.search(fail_time, pass_time, fast_enough)
      |> IO.inspect(label: "#{type} charge time")
    end)
    |> Enum.map(fn {:ok, rval} -> rval end)

  min_charge..max_charge
  |> Range.size()
  |> IO.inspect(label: "Ways to win")
end)
|> elem(0)
|> IO.inspect(label: "Time")
