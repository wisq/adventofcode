defmodule Beams do
  defmodule State do
    @enforce_keys [:grid, :bounds]
    defstruct(
      grid: nil,
      bounds: nil,
      position: {-1, 0},
      direction: {1, 0},
      history: %{}
    )
  end

  def run do
    IO.stream(:stdio, :line)
    |> Enum.with_index()
    |> Enum.flat_map(fn {line, y} ->
      line
      |> String.trim()
      |> String.graphemes()
      |> Enum.with_index()
      |> Enum.map(fn {char, x} ->
        {{x, y}, parse_grid_char(char)}
      end)
    end)
    |> build_state()
    |> walk()
    |> then(fn %State{history: hist} ->
      Enum.count(hist)
    end)
    |> IO.inspect(label: "Cells energized")
  end

  defp parse_grid_char("."), do: :empty

  defp parse_grid_char("/") do
    {:mirror,
     fn
       # northwards travel becomes eastwards and vice versa
       {-1, 0} -> {0, 1}
       {0, 1} -> {-1, 0}
       # southwards travel becomes westwards and vice versa
       {1, 0} -> {0, -1}
       {0, -1} -> {1, 0}
     end}
  end

  defp parse_grid_char("\\") do
    {:mirror,
     fn
       # northwards travel becomes westwards and vice versa
       {-1, 0} -> {0, -1}
       {0, -1} -> {-1, 0}
       # southwards travel becomes eastwards and vice versa
       {1, 0} -> {0, 1}
       {0, 1} -> {1, 0}
     end}
  end

  defp parse_grid_char("|") do
    {:splitter,
     fn
       {x, 0} when x in [-1, 1] -> [{0, -1}, {0, 1}]
       {0, _} = dir -> [dir]
     end}
  end

  defp parse_grid_char("-") do
    {:splitter,
     fn
       {0, y} when y in [-1, 1] -> [{-1, 0}, {1, 0}]
       {_, 0} = dir -> [dir]
     end}
  end

  defp build_state(grid) do
    coords = grid |> Enum.map(&elem(&1, 0))
    {min_x, max_x} = coords |> Enum.map(&elem(&1, 0)) |> Enum.min_max()
    {min_y, max_y} = coords |> Enum.map(&elem(&1, 1)) |> Enum.min_max()

    %State{
      grid: grid |> Enum.reject(fn {_, cell} -> cell == :empty end) |> Map.new(),
      bounds: {min_x..max_x, min_y..max_y}
    }
  end

  defp walk(state) do
    {x, y} = state.position
    {dx, dy} = dir = state.direction
    new_x = x + dx
    new_y = y + dy
    new_pos = {new_x, new_y}

    {bounds_x, bounds_y} = state.bounds

    cond do
      new_x not in bounds_x ->
        state

      new_y not in bounds_y ->
        state

      dir in Map.get(state.history, new_pos, []) ->
        state

      true ->
        %State{
          state
          | position: new_pos,
            history: state.history |> Map.update(new_pos, [dir], fn list -> [dir | list] end)
        }
        |> walk_step()
    end
  end

  defp walk_step(state) do
    case Map.fetch(state.grid, state.position) do
      :error -> state |> walk()
      {:ok, {:mirror, fun}} -> %State{state | direction: fun.(state.direction)} |> walk()
      {:ok, {:splitter, fun}} -> state |> split(fun.(state.direction))
    end
  end

  defp split(state, [dir]) do
    %State{state | direction: dir}
    |> walk()
  end

  defp split(state, [dir1, dir2]) do
    IO.inspect({state.position, state.direction}, label: "split")

    %State{state | direction: dir1}
    |> walk()
    |> then(fn new_state ->
      %State{state | direction: dir2, history: new_state.history}
    end)
    |> walk()
  end
end

Beams.run()
