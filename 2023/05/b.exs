defmodule SeedMap do
  def run do
    IO.read(:stdio, :eof)
    |> String.trim()
    |> String.split("\n\n")
    |> Enum.reduce(nil, &reduce_sections/2)
  end

  defp reduce_sections("seeds: " <> seeds, nil) do
    seeds
    |> String.split()
    |> Enum.map(&String.to_integer/1)
    |> Enum.chunk_every(2)
    |> Enum.map(fn [start, count] ->
      start..(start + count - 1)
    end)
    |> Enum.slice(3..3)
    |> IO.inspect(label: "Loaded seeds")
  end

  defp reduce_sections(section_text, input_ranges) do
    IO.puts("")
    [header | map_rows] = section_text |> String.split("\n")
    [_, from, to] = Regex.run(~r/^(\w+)-to-(\w+) map:$/, header)

    mapping = load_mapping(map_rows)

    input_ranges
    |> Enum.flat_map(fn range ->
      mapping
      |> Enum.flat_map_reduce(range, &split_range_by_mapping/2)
      |> then(fn
        {ranges, nil} -> ranges
        {ranges, acc} -> ranges ++ [acc]
      end)
    end)
    |> IO.inspect(label: "Mapped #{from} -> #{to}", charlists: :as_lists, limit: :infinity)
  end

  defp load_mapping(map_rows) do
    map_rows
    |> Enum.map(fn line ->
      [to_start, from_start, size] =
        line
        |> String.split(" ", parts: 3)
        |> Enum.map(&String.to_integer/1)

      from_range = from_start..(from_start + size - 1)
      {from_range, to_start}
    end)
    |> Enum.sort()
  end

  defp split_range_by_mapping(_, nil), do: {:halt, nil}

  defp split_range_by_mapping({from_range, to_start}, input) do
    if Range.disjoint?(from_range, input) do
      {[], input}
    else
      IO.puts("Taking #{inspect(input)} and mapping #{inspect(from_range)} -> #{to_start}")

      {in_before, to_map, in_after} = split_range(input, from_range)
      mapped = transform_range(to_map, from_range, to_start)

      output = if in_before, do: [in_before, mapped], else: [mapped]
      {output, in_after}
    end
  end

  defp split_range(in_min..in_max, map_min..map_max) do
    r_before = Range.new(in_min, map_min - 1, 1) |> non_empty_range()
    r_after = Range.new(map_max + 1, in_max, 1) |> non_empty_range()

    r_middle =
      Range.new(
        max(in_min, map_min),
        min(in_max, map_max),
        1
      )

    {r_before, r_middle, r_after}
  end

  defp non_empty_range(range) do
    case Range.size(range) do
      0 -> nil
      _ -> range
    end
  end

  defp transform_range(range, from_min.._, to_start) do
    offset = to_start - from_min
    Range.shift(range, offset)
  end
end

:timer.tc(fn ->
  SeedMap.run()
  |> Enum.min()
  |> IO.inspect(label: "Lowest location range")
end)
|> IO.inspect()
