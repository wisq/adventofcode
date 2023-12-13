defmodule Mirrors do
  def run do
    IO.read(:stdio, :eof)
    |> String.trim()
    |> String.split("\n\n")
    |> Enum.with_index()
    |> Enum.map(fn {grid, index} ->
      solve(grid)
      |> IO.inspect(label: "Solution for grid #{index}")
    end)
    |> Enum.map(fn
      {:vertical, n} -> n
      {:horizontal, n} -> n * 100
    end)
    |> Enum.sum()
    |> IO.inspect(label: "Sum")
  end

  defp solve(data) do
    lines = data |> String.split("\n")

    case solve_horizontal(lines) do
      {:ok, n} ->
        {:horizontal, n}

      :error ->
        {:ok, n} = solve_vertical(lines)
        {:vertical, n}
    end
  end

  defp solve_horizontal(lines), do: lines |> solve_generic()
  defp solve_vertical(lines), do: lines |> transpose() |> solve_generic()

  defp transpose(lines) do
    lines
    |> Enum.map(&String.to_charlist/1)
    |> Enum.zip()
    |> Enum.map(fn tuple ->
      tuple
      |> Tuple.to_list()
      |> String.Chars.to_string()
    end)
  end

  def solve_generic(lines) do
    lines
    |> Enum.with_index()
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce_while(:error, fn
      [{same, _i1}, {same, i2}], _ ->
        case is_mirrored(lines, i2) do
          true -> {:halt, {:ok, i2}}
          false -> {:cont, :error}
        end

      [{_, _}, {_, _}], _ ->
        {:cont, :error}
    end)
  end

  defp is_mirrored(lines, index) do
    {lines_before, lines_after} = Enum.split(lines, index)

    lines_before
    |> Enum.reverse()
    |> Enum.zip(lines_after)
    |> Enum.all?(fn
      {same, same} -> true
      {_, _} -> false
    end)
  end
end

Mirrors.run()
