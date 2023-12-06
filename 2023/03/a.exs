lines = IO.read(:stdio, :eof) |> String.split("\n")

symbols =
  lines
  |> Enum.with_index()
  |> Enum.flat_map(fn {line, row} ->
    Regex.scan(~r/[^\d\.]/, line, return: :index)
    |> Enum.map(fn [{col, 1}] -> {row, col} end)
  end)

has_symbol = fn num_row, num_col, num_size ->
  row_range = (num_row - 1)..(num_row + 1)
  col_range = (num_col - 1)..(num_col + num_size)

  symbols
  |> Enum.any?(fn {sym_row, sym_col} ->
    sym_row in row_range and sym_col in col_range
  end)
end

digits =
  lines
  |> Enum.with_index()
  |> Enum.flat_map(fn {line, row} ->
    Regex.scan(~r/\d+/, line, return: :index)
    |> Enum.map(fn [{col, size}] ->
      case has_symbol.(row, col, size) do
        true ->
          line
          |> String.slice(col, size)
          |> String.to_integer()

        false ->
          0
      end
    end)
  end)

digits
|> IO.inspect()
|> Enum.sum()
|> IO.inspect(label: "Sum of valid parts")
