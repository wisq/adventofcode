defmodule SpinCycle do
  def run(cycles) do
    load_grid()
    |> spin_cycle(cycles)
    |> inspect_grid()
    |> check_load()
  end

  defp load_grid do
    IO.read(:stdio, :eof)
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&String.to_charlist/1)
  end

  defp spin_cycle(grid, count) do
    # grid starts with left = west, up = north
    grid
    # change grid to left = north, up = west
    |> transpose()
    # enter loop
    |> spin_cycle_loop(count)
  end

  defp spin_cycle_loop(grid, remaining, history \\ %{})
  defp spin_cycle_loop(grid, 0, _), do: grid

  defp spin_cycle_loop(grid, remaining, history) do
    grid = grid |> one_spin_cycle()

    case Map.fetch(history, grid) do
      :error ->
        history = history |> Map.put(grid, remaining)
        spin_cycle_loop(grid, remaining - 1, history)

      {:ok, prev_remaining} ->
        cycle_size = prev_remaining - remaining
        IO.puts("#{remaining}: loop back to #{prev_remaining}, cycle size = #{cycle_size}")
        spin_cycle_loop(grid, rem(remaining - 1, cycle_size), history)
    end
  end

  defp one_spin_cycle(grid) do
    grid
    # roll rocks left (north)
    |> roll(:left)
    # change grid to left = west, up = north
    |> transpose()
    # roll rocks left (west)
    |> roll(:left)
    # change grid to left = north, up = west
    |> transpose()
    # roll rocks right (south)
    |> roll(:right)
    # change grid to left = west, up = north
    |> transpose()
    # roll rocks right (east)
    |> roll(:right)
    # change grid to left = north, up = west
    |> transpose()
  end

  defp transpose(grid) do
    grid
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
  end

  defp roll(grid, direction) when direction in [:left, :right] do
    grid
    |> Enum.map(fn row ->
      row
      |> Enum.chunk_by(fn
        ?# -> :block
        ?O -> :roll
        ?. -> :roll
      end)
      |> Enum.map(fn chunk ->
        chunk
        |> Enum.sort_by(
          fn
            ?# -> -1
            ?O -> 0
            ?. -> 1
          end,
          case direction do
            :left -> :asc
            :right -> :desc
          end
        )
      end)
      |> List.flatten()
    end)
  end

  defp check_load(grid) do
    # grid arrives with north = left, no rotation needed
    grid
    |> Enum.map(fn row ->
      row
      |> Enum.reverse()
      |> Enum.with_index(1)
      |> Enum.map(fn
        {?#, _} -> 0
        {?., _} -> 0
        {?O, i} -> i
      end)
      |> Enum.sum()
    end)
    |> Enum.sum()
    |> IO.inspect(label: "Load")
  end

  def inspect_grid(grid) do
    # grid arrives with left = north, up = west
    grid
    # change to left = west, up = north
    |> transpose()
    |> Enum.map(fn row -> [row, "\n"] end)
    |> IO.puts()

    grid
  end
end

case System.argv() do
  [] ->
    SpinCycle.run(1)

  [cycles] ->
    cycles
    |> String.to_integer()
    |> SpinCycle.run()

  _ ->
    IO.puts(:stderr, "Usage: #{:escript.script_name()} [number of spins] < input")
    exit({:shutdown, 1})
end
