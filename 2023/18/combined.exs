Mix.install([
  {:memoize, "~> 1.4"}
])

defmodule Parser.Standard do
  @directions %{
    "U" => {0, -1},
    "D" => {0, 1},
    "L" => {-1, 0},
    "R" => {1, 0}
  }

  def parse_line(line) do
    [direction, distance, _] = String.split(line, " ")

    {
      @directions |> Map.fetch!(direction),
      distance |> String.to_integer()
    }
  end
end

defmodule Parser.Reversed do
  @directions %{
    ?3 => {0, -1},
    ?1 => {0, 1},
    ?2 => {-1, 0},
    ?0 => {1, 0}
  }

  def parse_line(line) do
    [_, _, colour] = line |> String.trim() |> String.split(" ")
    <<"(#", distance::binary-size(5), direction, ")">> = colour

    {
      @directions |> Map.fetch!(direction),
      distance |> String.to_integer(16)
    }
  end
end

defmodule Digger do
  use Memoize

  defmodule BorderState do
    defstruct(
      position: {0, 0},
      history: []
    )
  end

  def run(parser) do
    IO.stream(:stdio, :line)
    |> status("Walking")
    |> Enum.reduce(%BorderState{}, fn line, state ->
      {direction, distance} = parser.parse_line(line)
      [new_pos | _] = path = generate_path(state.position, direction, distance)

      %BorderState{
        position: new_pos,
        history: path ++ state.history
      }
    end)
    |> Map.fetch!(:history)
    # |> inspect_dig()
    |> status("Counting")
    |> then(fn h ->
      Enum.count(h) |> IO.inspect(label: "Border size")
      h
    end)
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
    rows =
      border
      |> status("Grouping")
      |> Enum.group_by(fn {_, y} -> y end)
      |> status("Simplifying")
      |> Map.new(fn {y, coords} ->
        {y,
         coords
         |> Enum.map(fn {x, ^y} -> x end)
         |> MapSet.new()}
      end)

    rows
    |> status("Filling")
    |> Enum.map(fn {y, xs} ->
      prev_row = rows |> Map.get(y - 1, MapSet.new())
      next_row = rows |> Map.get(y + 1, MapSet.new())
      count_row_filled(xs, prev_row, next_row)
    end)
    |> status("Summing")
    |> Enum.sum()
  end

  defmemop count_row_filled(xs, prev_row, next_row) do
    xs
    |> Enum.sort()
    |> Enum.chunk_while(
      nil,
      fn
        # starting the first border block
        x, nil -> {:cont, {x, x + 1}}
        # continuing a border block
        x, {start, x} -> {:cont, {start, x + 1}}
        # jumping to the start of a new border block
        new_x, {start, old_x} -> {:cont, {start, old_x - 1}, {new_x, new_x + 1}}
      end,
      fn
        {start, old_x} -> {:cont, {start, old_x - 1}, nil}
      end
    )
    |> Enum.map_reduce({false, nil}, fn
      {x, x}, {inside, last_border} ->
        {1 + between_count(last_border, x, inside), {!inside, x}}

      {x1, x2}, {inside, last_border} ->
        dirs1 = border_y_directions(x1, prev_row, next_row)
        dirs2 = border_y_directions(x2, prev_row, next_row)
        between = between_count(last_border, x1, inside)
        inside = if dirs1 == dirs2, do: inside, else: !inside

        {x2 - x1 + 1 + between, {inside, x2}}
    end)
    |> then(fn {counts, {false, _}} -> counts end)
    |> Enum.sum()
  end

  defp status(rval, text) do
    IO.puts("#{text} ...")
    rval
  end

  defp between_count(nil, _, _), do: 0
  defp between_count(last, now, true), do: now - last - 1
  defp between_count(_, _, false), do: 0

  defp border_y_directions(x, next_row, prev_row) do
    {x in prev_row, x in next_row}
  end
end

case System.argv() do
  [] ->
    Digger.run(Parser.Standard)

  ["--reversed"] ->
    Digger.run(Parser.Reversed)

  _ ->
    IO.puts(:stderr, "Usage: #{:escript.script_name()} [--reversed] < input")
    exit({:shutdown, 1})
end
