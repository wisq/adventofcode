defmodule Hiking do
  def run() do
    IO.stream(:stdio, :line)
    |> Enum.with_index()
    |> Enum.flat_map(fn {line, y} ->
      line
      |> String.trim()
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.map(fn
        {".", x} -> {{x, y}, :path}
        {">", x} -> {{x, y}, :one_way_east}
        {"v", x} -> {{x, y}, :one_way_south}
        {"#", _} -> nil
      end)
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
    |> calculate_neighbours()
    |> find_paths()
    |> Enum.map(& &1.length)
    |> Enum.sort(:desc)
    |> IO.inspect(label: "Paths", charlists: :as_lists)
  end

  defp calculate_neighbours(trails) do
    trails
    |> Map.new(fn {pos, cell} ->
      {pos, cell_neighbours(cell, pos, trails)}
    end)
  end

  defp cell_neighbours(:one_way_east, {x, y}, _trails), do: [{x + 1, y}]
  defp cell_neighbours(:one_way_south, {x, y}, _trails), do: [{x, y + 1}]

  defp cell_neighbours(:path, {x, y}, trails) do
    [
      {x + 1, y},
      {x - 1, y},
      {x, y + 1},
      {x, y - 1}
    ]
    |> Enum.filter(&Map.has_key?(trails, &1))
  end

  defmodule Path do
    defstruct(
      position: nil,
      length: -1,
      seen: MapSet.new()
    )
  end

  defp find_paths(trails) do
    {start, target} = Map.keys(trails) |> Enum.min_max_by(fn {_, y} -> y end)

    %Path{}
    |> walk_step(start, target, trails)
  end

  defp walk_step(path, target, target, _trails) do
    [path |> add_step(target)]
  end

  defp walk_step(path, pos, target, trails) do
    next_steps =
      trails
      |> Map.fetch!(pos)
      |> Enum.reject(fn p -> p == path.position || p in path.seen end)

    case next_steps do
      [] ->
        []

      [p] ->
        path
        |> add_step(pos)
        |> walk_step(p, target, trails)

      [_ | _] = ps ->
        new_path = path |> add_step(pos)
        ps |> Enum.flat_map(fn p -> walk_step(new_path, p, target, trails) end)
    end
  end

  defp add_step(path, pos) do
    %Path{path | position: pos, length: path.length + 1, seen: MapSet.put(path.seen, pos)}
  end
end

Hiking.run()
