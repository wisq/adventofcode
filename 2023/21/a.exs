defmodule GardenPath do
  def run(steps) do
    IO.stream(:stdio, :line)
    |> Enum.with_index()
    |> Enum.flat_map_reduce(nil, fn {line, y}, start ->
      line
      |> String.trim()
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.flat_map_reduce(start, fn
        {"S", x}, nil -> {[], {x, y}}
        {"#", _}, start -> {[], start}
        {".", x}, start -> {[{x, y}], start}
      end)
    end)
    |> then(fn {garden, start} ->
      garden
      |> MapSet.new()
      |> solve(start, steps)
      |> Enum.filter(fn {_, cost} -> rem(cost, 2) == 1 end)
      |> Map.new()
      |> inspect_solutions(garden, start)
    end)
    |> Enum.count()
    |> IO.inspect(label: "Reachable plots")
  end

  defp solve(garden, start, steps) do
    solved = %{start => steps + 1}
    queue = [start]

    solve_pass(queue, solved, garden, steps)
  end

  defp solve_pass(_queue, solved, _garden, 0), do: solved

  defp solve_pass(queue, solved, garden, steps) do
    count = Enum.count(queue)
    IO.puts("Solving for steps #{steps}, queue size #{count}")

    queue
    |> Enum.chunk_every(count |> div(64) |> max(1))
    |> Task.async_stream(
      fn chunk ->
        chunk
        |> Enum.flat_map(&neighbours/1)
        |> Enum.reject(&Map.has_key?(solved, &1))
        |> Enum.filter(&(&1 in garden))
        |> Enum.map_reduce(%{}, fn pos, solved ->
          solved = Map.put(solved, pos, steps)
          {pos, solved}
        end)
      end,
      timeout: :infinity
    )
    |> Enum.flat_map_reduce(solved, fn {:ok, {chunk, their_solved}}, my_solved ->
      solved = Map.merge(my_solved, their_solved)
      {chunk, solved}
    end)
    |> then(fn {queue, solved} ->
      queue
      |> Enum.uniq()
      |> solve_pass(solved, garden, steps - 1)
    end)
  end

  defp neighbours({x, y}) do
    [
      {x + 1, y},
      {x - 1, y},
      {x, y + 1},
      {x, y - 1}
    ]
  end

  defp inspect_solutions(solved, garden, start) do
    {x1, x2} = garden |> Enum.map(fn {x, _} -> x end) |> Enum.min_max()
    {y1, y2} = garden |> Enum.map(fn {_, y} -> y end) |> Enum.min_max()

    y1..y2
    |> Enum.map(fn y ->
      x1..x2
      |> Enum.map(fn x ->
        pos = {x, y}

        cond do
          Map.has_key?(solved, pos) -> "O"
          pos == start -> "S"
          pos in garden -> "."
          true -> "#"
        end
      end)
      |> then(fn line -> [line, "\n"] end)
    end)
    |> IO.puts()

    solved
  end
end

case System.argv() do
  [steps] ->
    steps
    |> String.to_integer()
    |> GardenPath.run()

  _ ->
    IO.puts(:stderr, "Usage: #{:escript.script_name()} <steps> < input")
    exit({:shutdown, 1})
end
