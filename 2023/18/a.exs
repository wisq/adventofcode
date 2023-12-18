defmodule Digger do
  defmodule BorderState do
    defstruct(
      position: {0, 0},
      history: []
    )
  end

  @directions %{
    "U" => {0, -1},
    "D" => {0, 1},
    "L" => {-1, 0},
    "R" => {1, 0}
  }

  def run do
    IO.stream(:stdio, :line)
    |> Enum.reduce(%BorderState{}, fn line, state ->
      [direction, distance, _] = String.split(line, " ")
      direction = @directions |> Map.fetch!(direction)
      distance = distance |> String.to_integer()

      [new_pos | _] = path = generate_path(state.position, direction, distance)

      %BorderState{
        position: new_pos,
        history: path ++ state.history
      }
    end)
    |> Map.fetch!(:history)
    |> inspect_dig()
    |> count_interior()
    |> IO.inspect(label: "Cells dug")
  end

  defp generate_path({x, y}, {dx, dy}, count) do
    1..count
    |> Enum.map(fn mult ->
      {x + dx * mult, y + dy * mult}
    end)
    |> Enum.reverse()
  end

  defp count_interior(border) do
    border = MapSet.new(border)

    border
    |> Enum.group_by(fn {_, y} -> y end)
    |> Enum.map(fn {y, coords} ->
      coords
      |> Enum.sort()
      |> Enum.chunk_while(
        nil,
        fn
          # starting the first border block
          {x, ^y}, nil -> {:cont, {x, x + 1}}
          # continuing a border block
          {x, ^y}, {start, x} -> {:cont, {start, x + 1}}
          # jumping to the start of a new border block
          {new_x, ^y}, {start, old_x} -> {:cont, {{start, y}, {old_x - 1, y}}, {new_x, new_x + 1}}
        end,
        fn
          {start, old_x} -> {:cont, {{start, y}, {old_x - 1, y}}, nil}
        end
      )
      |> Enum.map_reduce({false, nil}, fn
        {{x, y}, {x, y}}, {inside, last_border} ->
          {1 + between_count(last_border, x, inside), {!inside, x}}

        {{x1, y} = left, {x2, y} = right}, {inside, last_border} ->
          left_dirs = border_y_directions(left, border)
          right_dirs = border_y_directions(right, border)
          between = between_count(last_border, x1, inside)
          inside = if left_dirs == right_dirs, do: inside, else: !inside

          {x2 - x1 + 1 + between, {inside, x2}}
      end)
      |> then(fn {counts, {false, _}} -> counts end)
      |> Enum.sum()
      |> IO.inspect(label: "Cells for row #{y}")
    end)
    |> Enum.sum()
  end

  defp between_count(nil, _, _), do: 0
  defp between_count(last, now, true), do: now - last - 1
  defp between_count(_, _, false), do: 0

  defp border_y_directions({x, y}, border) do
    [-1, 1]
    |> Enum.filter(fn dy ->
      {x, y + dy} in border
    end)
  end

  defp grid_bounds(cells) do
    {min_x, max_x} = cells |> Enum.map(fn {x, _} -> x end) |> Enum.min_max()
    {min_y, max_y} = cells |> Enum.map(fn {_, y} -> y end) |> Enum.min_max()
    {min_x..max_x, min_y..max_y}
  end

  defp inspect_dig(dug) do
    dug = MapSet.new(dug)
    {x_range, y_range} = grid_bounds(dug)

    y_range
    |> Enum.map(fn y ->
      [
        x_range
        |> Enum.map(fn x ->
          case {x, y} in dug do
            true -> "#"
            false -> "."
          end
        end),
        "\n"
      ]
    end)
    |> IO.puts()

    dug
  end
end

Digger.run()
