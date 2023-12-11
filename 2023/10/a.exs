defmodule Segment do
  defstruct(
    connections: [],
    is_start: false
  )
end

defmodule Coords do
  def add({row_a, column_a}, {row_b, column_b}) do
    {row_a + row_b, column_a + column_b}
  end

  def invert({row, column}), do: {-row, -column}
end

defmodule Pipes do
  north = {-1, 0}
  south = {1, 0}
  east = {0, 1}
  west = {0, -1}

  @symbols %{
    "|" => %Segment{connections: [north, south]},
    "-" => %Segment{connections: [east, west]},
    "L" => %Segment{connections: [north, east]},
    "J" => %Segment{connections: [north, west]},
    "7" => %Segment{connections: [south, west]},
    "F" => %Segment{connections: [south, east]},
    "." => nil,
    "S" => %Segment{is_start: true}
  }

  @neighbour_directions [
    north,
    south,
    east,
    west
  ]

  def run do
    IO.stream(:stdio, :line)
    |> Enum.with_index()
    |> Enum.flat_map(fn {row, row_index} ->
      row
      |> String.trim()
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.map(fn {cell, col_index} ->
        {{row_index, col_index}, Map.fetch!(@symbols, cell)}
      end)
    end)
    |> Map.new()
    |> connect_start()
    |> IO.inspect(label: "Grid")
    |> loop_stream()
    |> Enum.to_list()
    |> IO.inspect(label: "Loop")
    |> Enum.count()
    |> div(2)
    |> IO.inspect(label: "Half of length")
  end

  defp connect_start(grid) do
    coords = find_start_coords(grid)

    grid
    |> Map.update!(coords, fn start ->
      %Segment{start | connections: find_connections(grid, coords)}
    end)
  end

  defp loop_stream(grid) do
    start_coords = find_start_coords(grid)

    Stream.resource(
      fn ->
        {start_coords, Map.get(grid, start_coords).connections |> Enum.at(0)}
      end,
      fn
        :done ->
          {:halt, :done}

        {coords, direction} ->
          case Coords.add(coords, direction) do
            ^start_coords ->
              {[start_coords], :done}

            next_coords ->
              inverse = Coords.invert(direction)
              [next_direction] = Map.get(grid, next_coords).connections |> List.delete(inverse)
              {[next_coords], {next_coords, next_direction}}
          end
      end,
      fn _ -> nil end
    )
  end

  defp find_start_coords(grid) do
    grid
    |> Enum.find(fn
      {_, %Segment{is_start: is_start}} -> is_start
      {_, nil} -> false
    end)
    |> elem(0)
  end

  defp find_connections(grid, origin_coords) do
    @neighbour_directions
    |> Enum.filter(fn direction ->
      neighbour_coords = direction |> Coords.add(origin_coords)
      inverse = Coords.invert(direction)

      case Map.get(grid, neighbour_coords) do
        %Segment{connections: conns} -> inverse in conns
        nil -> false
      end
    end)
  end
end

Pipes.run()
