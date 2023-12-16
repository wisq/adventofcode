defmodule Beams do
  defmodule State do
    @enforce_keys [:grid, :bounds]
    defstruct(
      grid: nil,
      bounds: nil,
      position: {-1, 0},
      direction: {1, 0}
    )
  end

  @ets :beam_history

  def run do
    :ets.new(@ets, [:set, :public, :named_table])

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

    :ets.tab2list(@ets)
    |> Enum.map(fn {{pos, _dir}} -> pos end)
    |> Enum.uniq()
    |> Enum.count()
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
    {dx, dy} = state.direction
    new_x = x + dx
    new_y = y + dy
    new_pos = {new_x, new_y}

    {bounds_x, bounds_y} = state.bounds
    hist_key = {new_pos, state.direction}

    cond do
      new_x not in bounds_x ->
        state

      new_y not in bounds_y ->
        state

      :ets.lookup(@ets, hist_key) != [] ->
        state

      true ->
        :ets.insert(@ets, {hist_key})

        %State{state | position: new_pos}
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
    %State{state | direction: dir1} |> walk()
    %State{state | direction: dir2} |> walk()
  end
end

Beams.run()
