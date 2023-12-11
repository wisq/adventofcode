expansion_factor =
  case System.argv() do
    [] ->
      2

    [factor] ->
      factor |> String.to_integer()

    _ ->
      IO.puts(:stderr, "Usage: #{:escript.script_name()} [expansion factor] < input")
      exit({:shutdown, 1})
  end

galaxies =
  IO.stream(:stdio, :line)
  |> Enum.with_index()
  |> Enum.flat_map(fn {line, y} ->
    line
    |> String.trim()
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.filter(fn
      {"#", _} -> true
      {".", _} -> false
    end)
    |> Enum.map(fn {"#", x} ->
      {x, y}
    end)
  end)
  |> IO.inspect(label: "Galaxies")

used_x = galaxies |> Enum.map(fn {x, _y} -> x end) |> Enum.uniq()
used_y = galaxies |> Enum.map(fn {_x, y} -> y end) |> Enum.uniq()

unused_x =
  Enum.min_max(used_x)
  |> then(fn {min, max} -> min..max end)
  |> Enum.reject(&(&1 in used_x))
  |> IO.inspect(label: "Unused columns")

unused_y =
  Enum.min_max(used_y)
  |> then(fn {min, max} -> min..max end)
  |> Enum.reject(&(&1 in used_y))
  |> IO.inspect(label: "Unused rows")

galaxies =
  galaxies
  |> Enum.map(fn {x, y} ->
    {
      x + Enum.count(unused_x, &(&1 < x)) * (expansion_factor - 1),
      y + Enum.count(unused_y, &(&1 < y)) * (expansion_factor - 1)
    }
  end)
  |> IO.inspect(label: "Expanded galaxies")

galaxy_combos =
  galaxies
  |> Enum.with_index()
  |> Enum.flat_map(fn {g_a, index} ->
    galaxies
    |> Enum.drop(index + 1)
    |> Enum.map(fn g_b -> {g_a, g_b} end)
  end)

galaxy_combos
|> Enum.count()
|> IO.inspect(label: "Galaxy combo count")

galaxy_combos
|> Enum.map(fn {{a_x, a_y}, {b_x, b_y}} ->
  abs(a_x - b_x) + abs(a_y - b_y)
end)
|> Enum.sum()
|> IO.inspect(label: "Total distance")
