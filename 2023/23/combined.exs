defmodule Mode.Slopes do
  def parse_cell(".", pos), do: {pos, :path}
  def parse_cell(">", pos), do: {pos, :one_way_east}
  def parse_cell("v", pos), do: {pos, :one_way_south}
  def parse_cell("#", _), do: nil
end

defmodule Mode.Flat do
  def parse_cell(".", pos), do: {pos, :path}
  def parse_cell(">", pos), do: {pos, :path}
  def parse_cell("v", pos), do: {pos, :path}
  def parse_cell("#", _), do: nil
end

defmodule Hiking do
  def run(mode) do
    IO.stream(:stdio, :line)
    |> Enum.with_index()
    |> Enum.flat_map(fn {line, y} ->
      line
      |> String.trim()
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.map(fn {cell, x} -> mode.parse_cell(cell, {x, y}) end)
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
    |> find_neighbours()
    |> generate_graph()
    |> find_paths()
    |> Enum.sort(:desc)
    |> IO.inspect(label: "Paths", charlists: :as_lists)
  end

  defp find_neighbours(trails) do
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

  defmodule Node do
    @enforce_keys [:type, :neighbours]
    defstruct(@enforce_keys)
  end

  defp generate_graph(trails) do
    {start, target} = Map.keys(trails) |> Enum.min_max_by(fn {_, y} -> y end)

    nodes =
      trails
      |> Enum.filter(fn
        {^start, _} -> true
        {^target, _} -> true
        {_, neighbours} -> Enum.count(neighbours) > 2
      end)
      |> Map.new()

    node_types = %{
      start => :start,
      target => :target
    }

    nodes
    |> Enum.map(fn {pos, neighbours} ->
      node = %Node{
        type: node_types |> Map.get(pos, :intersection),
        neighbours:
          neighbours
          |> Enum.map(&walk_until_node(pos, &1, nodes, trails))
          |> Enum.reject(&is_nil/1)
      }

      {pos, node}
    end)
    |> Map.new()
    |> IO.inspect(label: "Nodes")
  end

  defp walk_until_node(from, to, nodes, trails, length \\ 1) do
    case Map.has_key?(nodes, to) do
      true ->
        {to, length}

      false ->
        case trails |> Map.fetch!(to) |> Enum.reject(fn p -> p == from end) do
          [] -> nil
          [next] -> walk_until_node(to, next, nodes, trails, length + 1)
        end
    end
  end

  defmodule Path do
    defstruct(
      position: nil,
      seen: MapSet.new(),
      length: 0
    )
  end

  defp find_paths(trails) do
    start = Map.keys(trails) |> Enum.min_by(fn {_, y} -> y end)

    %Path{}
    |> add_step(start, 0)
    |> walk_neighbours(start, trails)
  end

  defp walk_neighbours(path, pos, trails) do
    case trails |> Map.fetch!(pos) do
      %Node{type: :target} ->
        [path.length]

      %Node{neighbours: neighbours} ->
        neighbours
        |> Enum.reject(fn {next_pos, _} -> next_pos in path.seen end)
        |> Enum.flat_map(fn {next_pos, cost} ->
          path
          |> add_step(next_pos, cost)
          |> walk_neighbours(next_pos, trails)
        end)
    end
  end

  defp add_step(path, pos, cost) do
    %Path{
      path
      | position: pos,
        seen: MapSet.put(path.seen, pos),
        length: path.length + cost
    }
  end
end

case System.argv() do
  [] ->
    Hiking.run(Mode.Slopes)

  ["--flat"] ->
    Hiking.run(Mode.Flat)

  _ ->
    IO.puts(:stderr, "Usage: #{:escript.script_name()} [--flat] < input")
    exit({:shutdown, 1})
end
