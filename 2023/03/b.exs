lines = IO.read(:stdio, :eof) |> String.split("\n")

digits =
  lines
  |> Enum.with_index()
  |> Enum.flat_map(fn {line, row} ->
    Regex.scan(~r/\d+/, line, return: :index)
    |> Enum.map(fn [{col, size}] ->
      number =
        line
        |> String.slice(col, size)
        |> String.to_integer()

      {row..row, col..(col + size - 1), number}
    end)
  end)

numbers_near = fn row, col ->
  row_range = (row - 1)..(row + 1)
  col_range = (col - 1)..(col + 1)

  digits
  |> Enum.reject(fn {r, c, _} ->
    Range.disjoint?(row_range, r) || Range.disjoint?(col_range, c)
  end)
  |> Enum.map(fn {_, _, n} -> n end)
end

gears =
  lines
  |> Enum.with_index()
  |> Enum.flat_map(fn {line, row} ->
    Regex.scan(~r/\*/, line, return: :index)
    |> Enum.flat_map(fn [{col, 1}] ->
      case numbers_near.(row, col) do
        [n1, n2] -> [{n1, n2}]
        _ -> []
      end
    end)
  end)

gears
|> Enum.map(fn {n1, n2} -> n1 * n2 end)
|> Enum.sum()
|> IO.inspect(label: "Sum")
