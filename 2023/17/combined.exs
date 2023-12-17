defmodule Mode.Regular do
  def next_directions({:north, 3}), do: [:east, :west]
  def next_directions({:south, 3}), do: [:east, :west]
  def next_directions({:east, 3}), do: [:north, :south]
  def next_directions({:west, 3}), do: [:north, :south]

  def next_directions({:north, _}), do: [:east, :west, :north]
  def next_directions({:south, _}), do: [:east, :west, :south]
  def next_directions({:east, _}), do: [:north, :south, :east]
  def next_directions({:west, _}), do: [:north, :south, :west]

  def next_directions({nil, 0}), do: [:north, :south, :east, :west]

  def reject_final?({_, _}), do: false
end

defmodule Mode.Ultra do
  def next_directions({:north, 10}), do: [:east, :west]
  def next_directions({:south, 10}), do: [:east, :west]
  def next_directions({:east, 10}), do: [:north, :south]
  def next_directions({:west, 10}), do: [:north, :south]

  def next_directions({:north, n}) when n in 1..3, do: [:north]
  def next_directions({:south, n}) when n in 1..3, do: [:south]
  def next_directions({:east, n}) when n in 1..3, do: [:east]
  def next_directions({:west, n}) when n in 1..3, do: [:west]

  def next_directions({:north, _}), do: [:east, :west, :north]
  def next_directions({:south, _}), do: [:east, :west, :south]
  def next_directions({:east, _}), do: [:north, :south, :east]
  def next_directions({:west, _}), do: [:north, :south, :west]

  def next_directions({nil, 0}), do: [:north, :south, :east, :west]

  def reject_final?({_, count}), do: count < 4
end

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

  def run(mode) do
    block = load_block()

    block
    |> best_path(mode)
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

  defp best_path(block, mode) do
    dist = distance(block.start, block.finish)

    [%Path{position: block.start, distance_to_goal: dist}]
    |> walk_best_path(block, mode, dist + 1)
  end

  defp walk_best_path(paths, block, mode, min_distance) do
    best =
      paths
      |> Enum.min_by(fn
        %Path{cost: c, distance_to_goal: d} -> {c, -d}
      end)

    distance = best.distance_to_goal

    min_distance =
      case distance < min_distance do
        true -> distance |> IO.inspect(label: "Distance")
        false -> min_distance
      end

    {new_best, new_walked} =
      best.last_moves
      |> mode.next_directions()
      |> Enum.flat_map_reduce(block.walked, fn direction, walked ->
        new_pos = move(best.position, direction)

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

          new_pos == block.finish && mode.reject_final?(new_last_moves) ->
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

    # Debugging:
    # inspect_new_paths(new_best, best)
    new_block = %Block{block | walked: new_walked}

    case Enum.find(new_best, &(&1.position == block.finish)) do
      %Path{} = path ->
        path

      _ ->
        (new_best ++ List.delete(paths, best))
        |> walk_best_path(new_block, mode, min_distance)
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

  defp out_of_bounds({x, y}, {rx, ry}), do: x not in rx or y not in ry

  # Used during debugging, or just for a cool visualisation.
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

case System.argv() do
  ["--ultra"] ->
    LavaWalker.run(Mode.Ultra)

  [] ->
    LavaWalker.run(Mode.Regular)

  _ ->
    IO.puts(:stderr, "Usage: #{:escript.script_name()} [--ultra] < input")
    exit({:shutdown, 1})
end
