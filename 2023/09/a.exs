defmodule Oasis do
  def run do
    IO.stream(:stdio, :line)
    |> Enum.with_index(1)
    |> Enum.map(fn {line, index} ->
      line
      |> String.split()
      |> Enum.map(&String.to_integer/1)
      |> IO.inspect(label: "Line #{index}")
      |> extrapolate_line()
      |> IO.inspect(label: "Sum for line #{index}")
    end)
    |> Enum.sum()
    |> IO.inspect(label: "Total sum")
  end

  defp extrapolate_line(line) do
    case Enum.uniq(line) do
      [0] ->
        0

      _ ->
        line
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.map(fn [a, b] -> b - a end)
        |> extrapolate_line()
        |> Kernel.+(Enum.at(line, -1))
    end
  end
end

Oasis.run()
