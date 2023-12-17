defmodule LavaWalker do
  defmodule Block do
    @enforce_keys [:grid, :bounds, :start, :finish]
    defstruct(
      grid: nil,
      bounds: nil,
      start: nil,
      finish: nil,
      walked: %{}
    )
  end

  defmodule Path do
    @enforce_keys [:position, :distance_to_goal]
    defstruct(
      position: nil,
      moves: [],
      last_moves: {nil, 0},
      cost: 0,
      distance_to_goal: nil
    )
  end

  def run do
    block = load_block()

    block
    |> best_path()
    |> inspect_path_moves(block)
    |> IO.inspect(label: "Best path")
  end

  defp load_block do
    IO.stream(:stdio, :line)
    |> Enum.with_index()
    |> Enum.flat_map(fn {line, y} ->
      line
      |> String.trim()
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.map(fn {cell, x} ->
        {{x, y}, String.to_integer(cell)}
      end)
    end)
    |> Map.new()
    |> then(fn grid ->
      {{min_x, min_y}, {max_x, max_y}} = grid |> Map.keys() |> Enum.min_max()

      %Block{
        grid: grid,
        bounds: {min_x..max_x, min_y..max_y},
        start: {min_x, min_y},
        finish: {max_x, max_y}
      }
    end)
  end

  defp best_path(block) do
    [
      %Path{position: block.start, distance_to_goal: distance(block.start, block.finish)}
    ]
    |> walk_best_path(block)
  end

  defp walk_best_path(paths, block) do
    best =
      paths
      |> Enum.min_by(fn
        %Path{cost: c, distance_to_goal: d} -> {c, -d}
      end)

    {new_best, new_walked} =
      best.last_moves
      |> next_directions()
      |> Enum.flat_map_reduce(block.walked, fn direction, walked ->
        new_pos = move(best.position, direction)

        {_, dir_count} =
          new_last_moves =
          case best.last_moves do
            {^direction, count} -> {direction, count + 1}
            {_, _} -> {direction, 1}
          end

        cond do
          out_of_bounds(new_pos, block.bounds) ->
            {[], walked}

          new_last_moves in Map.get(walked, new_pos, []) ->
            {[], walked}

          new_pos == block.finish && dir_count < 4 ->
            # we're at the end, but we haven't gone far enough in a straight line
            {[], walked}

          true ->
            path =
              %Path{
                position: new_pos,
                cost: best.cost + Map.fetch!(block.grid, new_pos),
                distance_to_goal: best.distance_to_goal |> update_distance(direction),
                moves: [direction | best.moves],
                last_moves: new_last_moves
              }

            walked =
              Map.update(walked, new_pos, [new_last_moves], fn
                rest -> [new_last_moves | rest]
              end)

            {[path], walked}
        end
      end)

    # inspect_new_paths(new_best, best)
    new_block = %Block{block | walked: new_walked}

    case Enum.find(new_best, &(&1.position == block.finish)) do
      %Path{} = path ->
        path

      _ ->
        (new_best ++ List.delete(paths, best))
        |> walk_best_path(new_block)
    end
  end

  defp distance({ax, ay}, {bx, by}), do: abs(bx - ax) + abs(by - ay)

  defp update_distance(dist, :north), do: dist + 1
  defp update_distance(dist, :south), do: dist - 1
  defp update_distance(dist, :east), do: dist - 1
  defp update_distance(dist, :west), do: dist + 1

  defp move({x, y}, :north), do: {x, y - 1}
  defp move({x, y}, :south), do: {x, y + 1}
  defp move({x, y}, :east), do: {x + 1, y}
  defp move({x, y}, :west), do: {x - 1, y}

  defp next_directions({:north, 10}), do: [:east, :west]
  defp next_directions({:south, 10}), do: [:east, :west]
  defp next_directions({:east, 10}), do: [:north, :south]
  defp next_directions({:west, 10}), do: [:north, :south]

  defp next_directions({:north, n}) when n in 1..3, do: [:north]
  defp next_directions({:south, n}) when n in 1..3, do: [:south]
  defp next_directions({:east, n}) when n in 1..3, do: [:east]
  defp next_directions({:west, n}) when n in 1..3, do: [:west]

  defp next_directions({:north, _}), do: [:east, :west, :north]
  defp next_directions({:south, _}), do: [:east, :west, :south]
  defp next_directions({:east, _}), do: [:north, :south, :east]
  defp next_directions({:west, _}), do: [:north, :south, :west]

  defp next_directions({nil, 0}), do: [:north, :south, :east, :west]

  defp out_of_bounds({x, y}, {rx, ry}), do: x not in rx or y not in ry

  def inspect_new_paths(new_paths, old_path) do
    [
      render_at(old_path.position, ".", 1),
      new_paths
      |> Enum.map(fn path ->
        render_at(path.position, "@", 1)
      end)
    ]
    |> IO.puts()

    new_paths
  end

  defp render_at({x, y}, str, size) do
    [
      "\e[#{y};#{x * size}H",
      str |> String.pad_leading(size)
    ]
  end

  defp inspect_path_moves(path, block) do
    expected_finish = block.finish
    expected_cost = path.cost

    {seen, actual} =
      path.moves
      |> Enum.reverse()
      |> Enum.map_reduce({block.start, 0}, fn direction, {pos, cost} ->
        new_pos = move(pos, direction)
        new_cost = cost + Map.fetch!(block.grid, new_pos)
        {{new_pos, direction}, {new_pos, new_cost}}
      end)

    {^expected_finish, ^expected_cost} = actual

    seen = Map.new(seen)
    {rx, ry} = block.bounds

    ry
    |> Enum.map(fn y ->
      rx
      |> Enum.map(fn x ->
        case Map.fetch(seen, {x, y}) do
          {:ok, dir} -> inspect_direction(dir)
          :error -> "."
        end
      end)
      |> then(fn cols -> [cols, "\n"] end)
    end)
    |> IO.puts()

    path.moves
    |> Enum.chunk_by(& &1)
    |> Enum.max_by(&Enum.count/1)
    |> IO.inspect(label: "Most consecutive directions")

    path
  end

  defp inspect_direction(:north), do: "^"
  defp inspect_direction(:south), do: "v"
  defp inspect_direction(:east), do: ">"
  defp inspect_direction(:west), do: "<"
end

LavaWalker.run()
