defmodule Springs do
  def run do
    IO.stream(:stdio, :line)
    |> Enum.map(fn line ->
      {symbols, groups} = parse_line(line)

      possible_solutions(symbols)
      |> Enum.count(&matches_groups(&1, groups))
    end)
    |> IO.inspect(label: "Possible arrangements")
    |> Enum.sum()
    |> IO.inspect(label: "Sum")
  end

  defp parse_line(line) do
    [symbols, groups] = line |> String.split()

    symbols =
      symbols
      |> String.graphemes()
      |> Enum.map(fn
        "." -> 0
        "#" -> 1
        "?" -> nil
      end)

    groups =
      groups
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)

    {symbols, groups}
  end

  defp possible_solutions(symbols) do
    bitcount = symbols |> Enum.count(&is_nil/1)

    0..(2 ** bitcount - 1)
    |> Stream.map(fn bits ->
      symbols
      |> Enum.map_reduce(bits, fn
        1, b -> {1, b}
        0, b -> {0, b}
        nil, b -> {rem(b, 2), div(b, 2)}
      end)
      |> elem(0)
    end)
  end

  defp matches_groups(symbols, expected) do
    symbols
    |> Enum.chunk_by(& &1)
    |> Enum.filter(fn
      [0 | _] -> false
      [1 | _] -> true
    end)
    |> Enum.map(&Enum.count/1)
    |> then(fn actual -> actual == expected end)
  end
end

Springs.run()
