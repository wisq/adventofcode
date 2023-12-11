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
    "." => :ground,
    "S" => %Segment{is_start: true}
  }

  @inverse_symbols @symbols
                   |> Enum.filter(fn
                     {_, %Segment{connections: [_, _]}} -> true
                     _ -> false
                   end)
                   |> Map.new(fn {symbol, %Segment{connections: conns}} ->
                     {Enum.sort(conns), symbol}
                   end)

  @neighbour_directions [
    north,
    south,
    east,
    west
  ]

  def run do
    grid =
      load_grid()
      |> connect_start()
      |> inspect_grid()

    path =
      grid
      |> path_stream()
      |> Enum.to_list()
      |> IO.inspect(label: "Path")

    path
    |> Enum.count()
    |> div(2)
    |> IO.inspect(label: "Half of path length")

    grid
    |> delete_non_path_segments(path)
    |> inflate()
    |> flood_fill_outer_cells()
    |> inspect_grid()
    |> Enum.count(fn
      {_, :ground} -> true
      {_, _} -> false
    end)
    |> IO.inspect(label: "Area of inner ground")
  end

  defp load_grid do
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
  end

  defp connect_start(grid) do
    coords = find_start_coords(grid)

    grid
    |> Map.update!(coords, fn start ->
      %Segment{start | connections: find_connections(grid, coords)}
    end)
  end

  defp path_stream(grid) do
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
      {_, :ground} -> false
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
        :ground -> false
        nil -> false
      end
    end)
  end

  defp delete_non_path_segments(grid, path) do
    path = MapSet.new(path)

    grid
    |> Map.new(fn
      {coord, :ground} ->
        {coord, :ground}

      {coord, %Segment{} = segment} ->
        case coord in path do
          true -> {coord, segment}
          false -> {coord, :ground}
        end
    end)
  end

  defp inflate(grid) do
    grid =
      grid
      |> Map.new(fn {{row, col}, cell} ->
        {{row * 2, col * 2}, cell}
      end)

    {{max_row, max_col}, _} = Enum.max(grid)

    existing_coords = Map.keys(grid) |> MapSet.new()

    new_coords =
      0..max_row
      |> Enum.flat_map(fn row ->
        0..max_col
        |> Enum.map(fn col -> {row, col} end)
      end)
      |> MapSet.new()
      |> MapSet.difference(existing_coords)

    new_coords
    |> Map.new(fn coord ->
      case find_connections(grid, coord) do
        [] -> {coord, :filler}
        [_ | _] = conns -> {coord, %Segment{connections: conns}}
      end
    end)
    |> Map.merge(grid)
  end

  defp inspect_grid(grid) do
    grid
    |> Enum.group_by(fn {{row, _}, _} -> row end)
    |> Enum.sort()
    |> Enum.map(fn {_, row} ->
      row
      |> Enum.sort()
      |> Enum.map(fn
        {_, %Segment{connections: conns}} -> Map.fetch!(@inverse_symbols, Enum.sort(conns))
        {_, :ground} -> "."
        {_, :filler} -> " "
        {_, :outer} -> "O"
      end)
      |> then(fn row -> [row, "\n"] end)
    end)
    |> IO.puts()

    grid
  end

  defp flood_fill_outer_cells(grid) do
    {{max_row, max_col}, _} = Enum.max(grid)

    outer_coords =
      [
        0..max_col |> Enum.map(fn col -> {0, col} end),
        0..max_col |> Enum.map(fn col -> {max_row, col} end),
        0..max_row |> Enum.map(fn row -> {row, 0} end),
        0..max_row |> Enum.map(fn row -> {row, max_col} end)
      ]
      |> List.flatten()
      |> Enum.uniq()
      |> Enum.filter(fn coord ->
        Map.get(grid, coord) in [:ground, :filler]
      end)
      |> MapSet.new()

    grid
    |> recursive_fill(outer_coords, :outer)
  end

  defp recursive_fill(grid, fill_coords, new_cell) do
    fill_map =
      fill_coords
      |> Map.new(fn coords -> {coords, new_cell} end)

    neighbour_coords =
      fill_coords
      |> Enum.flat_map(fn coords ->
        @neighbour_directions
        |> Enum.map(&Coords.add(coords, &1))
        |> Enum.reject(&(&1 in fill_coords))
        |> Enum.filter(fn coords ->
          case Map.get(grid, coords) do
            :filler -> true
            :ground -> true
            ^new_cell -> false
            nil -> false
            %Segment{} -> false
          end
        end)
      end)
      |> MapSet.new()

    grid
    |> Map.merge(fill_map)
    |> then(fn grid ->
      case Enum.empty?(neighbour_coords) do
        true -> grid
        false -> recursive_fill(grid, neighbour_coords, new_cell)
      end
    end)
  end
end

Pipes.run()
