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
    lines = lines |> Enum.map(&to_binary_number/1)

    lines
    |> Enum.with_index()
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.reduce_while(:error, fn
      [{n1, _i1}, {n2, i2}], _ ->
        case (n1 == n2 || is_1bit_diff(n1, n2)) && is_mirrored(lines, i2) do
          true -> {:halt, {:ok, i2}}
          false -> {:cont, :error}
        end
    end)
  end

  def is_mirrored(lines, index) do
    {lines_before, lines_after} = Enum.split(lines, index)

    lines_before
    |> Enum.reverse()
    |> Enum.zip(lines_after)
    |> Enum.reduce_while(1, fn
      {same, same}, t ->
        {:cont, t}

      {n1, n2}, t ->
        case is_1bit_diff(n1, n2) do
          true ->
            case t do
              0 -> {:halt, false}
              n -> {:cont, n - 1}
            end

          false ->
            {:halt, false}
        end
    end)
    |> then(fn
      0 -> true
      _ -> false
    end)
  end

  defp to_binary_number(str) do
    str
    |> String.replace("#", "1")
    |> String.replace(".", "0")
    |> String.to_integer(2)
  end

  defp is_1bit_diff(n1, n2) do
    diff = abs(n1 - n2)
    Bitwise.band(diff, diff - 1) == 0
  end
end

Mirrors.run()
