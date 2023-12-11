defmodule Segment do
  defstruct(
    connections: [],
    is_start: false
  )
end

defmodule Grid do
  def update(grid, {row_index, col_index}, fun) do
    grid
    |> List.update_at(row_index, fn row ->
      row
      |> List.update_at(col_index, fun)
    end)
  end

  def get(grid, {row_index, col_index}) do
    grid
    |> Enum.at(row_index)
    |> Enum.at(col_index)
  end
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
    |> Enum.map(fn line ->
      line
      |> String.trim()
      |> String.graphemes()
      |> Enum.map(&Map.fetch!(@symbols, &1))
    end)
    |> loop_stream()
    |> Enum.to_list()
    |> IO.inspect(label: "Loop")
    |> Enum.count()
    |> div(2)
    |> IO.inspect(label: "Half of length")
  end

  defp loop_stream(grid) do
    start_coords = find_start(grid)
    grid = connect_start(grid, start_coords)
    IO.inspect(grid, label: "Grid")

    Stream.resource(
      fn ->
        {start_coords, Grid.get(grid, start_coords).connections |> Enum.at(0)}
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
              [next_direction] = Grid.get(grid, next_coords).connections |> List.delete(inverse)
              {[next_coords], {next_coords, next_direction}}
          end
      end,
      fn _ -> nil end
    )
  end

  defp find_start(grid) do
    grid
    |> Enum.with_index()
    |> Enum.reduce_while(nil, fn {row, row_index}, _ ->
      case row |> Enum.find_index(&(&1 && &1.is_start)) do
        nil -> {:cont, nil}
        col_index -> {:halt, {row_index, col_index}}
      end
    end)
  end

  defp connect_start(grid, coords) do
    grid
    |> Grid.update(coords, fn %Segment{is_start: true} = start ->
      %Segment{start | connections: find_connections(grid, coords)}
    end)
  end

  defp find_connections(grid, origin_coords) do
    @neighbour_directions
    |> Enum.filter(fn direction ->
      neighbour_coords = direction |> Coords.add(origin_coords)
      inverse = Coords.invert(direction)

      case Grid.get(grid, neighbour_coords) do
        %Segment{connections: conns} -> inverse in conns
        nil -> false
      end
    end)
  end
end

Pipes.run()
