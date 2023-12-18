defmodule Digger do
  defmodule BorderState do
    defstruct(
      position: {0, 0},
      history: []
    )
  end

  defmodule FillState do
    @enforce_keys [:filled, :queue]
    defstruct(@enforce_keys)
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
    |> fill_interior()
    |> inspect_dig()
    |> Enum.count()
    |> IO.inspect(label: "Cells dug")
  end

  defp generate_path({x, y}, {dx, dy}, count) do
    1..count
    |> Enum.map(fn mult ->
      {x + dx * mult, y + dy * mult}
    end)
    |> Enum.reverse()
  end

  defp fill_interior(border) do
    border = MapSet.new(border)
    {x_range, y_range} = grid_bounds(border)

    start_y = Enum.min(y_range) + 1

    start_x =
      x_range
      |> Enum.find(fn x ->
        {x, start_y - 1} in border and {x, start_y} not in border
      end)

    %FillState{
      filled: border,
      queue: [{start_x, start_y}] |> MapSet.new()
    }
    |> flood_fill()
    |> Map.fetch!(:filled)
  end

  defp flood_fill(state) do
    filled = state.filled

    new_coords =
      state.queue
      |> Enum.flat_map(fn coord ->
        neighbour_cells(coord)
        |> Enum.reject(&(&1 in filled))
      end)

    case new_coords do
      [] ->
        state

      _ ->
        new_coords = MapSet.new(new_coords)

        %FillState{
          filled: MapSet.union(filled, new_coords),
          queue: new_coords
        }
        |> flood_fill()
    end
  end

  defp neighbour_cells({x, y}) do
    [
      {x, y - 1},
      {x, y + 1},
      {x - 1, y},
      {x + 1, y}
    ]
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
