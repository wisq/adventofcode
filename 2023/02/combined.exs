defmodule CubeGame do
  defmodule Cubes do
    defstruct(
      red: 0,
      green: 0,
      blue: 0
    )

    def new([r, g, b]) do
      %__MODULE__{red: r, green: g, blue: b}
    end

    def parse(text) do
      text
      |> String.split(", ")
      |> Enum.map(fn part ->
        [count, colour] = String.split(part, " ", parts: 2)

        {
          String.to_existing_atom(colour),
          String.to_integer(count)
        }
      end)
      |> then(&struct!(__MODULE__, &1))
    end

    def expand(%Cubes{} = c1, %Cubes{} = c2) do
      %Cubes{
        red: max(c1.red, c2.red),
        green: max(c1.green, c2.green),
        blue: max(c1.blue, c2.blue)
      }
    end

    def power(%Cubes{} = c) do
      c.red * c.green * c.blue
    end
  end

  def sum_possible(%Cubes{} = bag) do
    IO.stream(:stdio, :line)
    |> Stream.map(&Regex.run(~r/^Game (\d+): (.*)$/, &1))
    |> Stream.map(fn [_, game_number, draws] ->
      draws
      |> String.split("; ")
      |> Stream.map(fn draw ->
        Cubes.parse(draw)
        |> possible_draw?(bag)
      end)
      |> Enum.all?()
      |> then(fn
        true ->
          String.to_integer(game_number)
          |> IO.inspect(label: "Game is possible")

        false ->
          0
      end)
    end)
    |> Enum.sum()
    |> IO.inspect()
  end

  def sum_powers do
    IO.stream(:stdio, :line)
    |> Stream.map(&Regex.run(~r/^Game (\d+): (.*)$/, &1))
    |> Stream.map(fn [_, _, draws] ->
      draws
      |> String.split("; ")
      |> Stream.map(&Cubes.parse/1)
      |> Enum.reduce(&Cubes.expand/2)
      |> Cubes.power()
    end)
    |> Enum.sum()
    |> IO.inspect()
  end

  defp possible_draw?(%Cubes{} = draw, %Cubes{} = bag) do
    [:red, :green, :blue]
    |> Enum.all?(fn colour ->
      in_draw = Map.fetch!(draw, colour)
      in_bag = Map.fetch!(bag, colour)

      if in_draw > in_bag do
        IO.inspect(draw, label: "Too many #{colour}s")
        false
      else
        true
      end
    end)
  end
end

case System.argv() do
  [_, _, _] = args ->
    args
    |> Enum.map(&String.to_integer/1)
    |> CubeGame.Cubes.new()
    |> CubeGame.sum_possible()

  [] ->
    CubeGame.sum_powers()

  _ ->
    IO.puts(:stderr, "Usage: #{:escript.script_name()} [r g b] < input")
    exit({:shutdown, 1})
end
