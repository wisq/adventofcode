Mix.install([
  {:memoize, "~> 1.4"}
])

defmodule Springs do
  use Memoize

  def run(fold_factor) do
    IO.stream(:stdio, :line)
    |> Enum.with_index(1)
    |> Task.async_stream(
      fn {line, index} ->
        {symbols, groups} = parse_line(line, fold_factor)

        count_solutions(symbols, groups)
        |> IO.inspect(label: "Line #{index} possible arrangements")
      end,
      timeout: :infinity
    )
    |> Enum.map(fn {:ok, n} -> n end)
    |> Enum.sum()
    |> IO.inspect(label: "Sum")
  end

  defp parse_line(line, fold_factor) do
    [symbols, groups] = line |> String.split()

    symbols =
      symbols
      |> String.graphemes()
      |> Enum.map(fn
        "." -> 0
        "#" -> 1
        "?" -> nil
      end)
      |> then(fn syms ->
        1..fold_factor
        |> Enum.map(fn _ -> syms end)
        |> Enum.intersperse(nil)
        |> List.flatten()
      end)

    groups =
      groups
      |> String.split(",")
      |> Enum.map(&String.to_integer/1)
      |> then(fn groups ->
        1..fold_factor
        |> Enum.flat_map(fn _ -> groups end)
      end)

    {symbols, groups}
  end

  # line ends with all groups satisfied
  defmemop(count_solutions([], []), do: 1)
  # line ends at the same time as the final group
  defmemop(count_solutions([], [0]), do: 1)
  # line ends with unfinished group(s)
  defmemop(count_solutions([], _), do: 0)

  # line has no more groups, but here's a group
  defmemop(count_solutions([1 | _], []), do: 0)
  # line has no more groups, but that's tentatively okay
  defmemop(count_solutions([0 | rest], []), do: count_solutions(rest, []))
  defmemop(count_solutions([nil | rest], []), do: count_solutions(rest, []))

  defmemop count_solutions([sym_head | sym_rest], [gr_head | gr_rest] = groups) do
    case {sym_head, gr_head} do
      {0, 0} ->
        # a group just ended
        count_solutions(sym_rest, gr_rest)

      {0, n} when n > 0 ->
        # we're between groups
        count_solutions(sym_rest, groups)

      {0, n} when n < 0 ->
        # we're in a group but it ends too soon, impossible
        0

      {1, 0} ->
        # our group should have ended already, impossible
        0

      {1, n} when n > 0 ->
        # we're starting a new group
        count_solutions(sym_rest, [0 - gr_head + 1 | gr_rest])

      {1, n} when n < 0 ->
        # we're inside a group
        count_solutions(sym_rest, [n + 1 | gr_rest])

      {nil, 0} ->
        # we MUST end this group
        # treat this as a zero and continue
        count_solutions(sym_rest, gr_rest)

      {nil, n} when n < 0 ->
        # we MUST continue this group
        # treat this as a one and continue
        count_solutions(sym_rest, [n + 1 | gr_rest])

      {nil, n} when n > 0 ->
        # we could either start a group now, or start it later
        a = count_solutions([0 | sym_rest], groups)
        b = count_solutions([1 | sym_rest], groups)
        a + b
    end
  end

  ~S"""
  defp inspect_branch(0, _symbols, _groups), do: 0

  defp inspect_branch(n, symbols, groups) do
    IO.puts("#{n}\t#{to_line(symbols, groups)}")
    n
  end

  defp to_line(symbols, groups) do
    [
      symbols
      |> Enum.map(fn
        0 -> "."
        1 -> "#"
        nil -> "?"
      end),
      groups
      |> Enum.join(",")
    ]
    |> Enum.join("\t")
  end
  """
end

case System.argv() do
  [] ->
    Springs.run(1)

  [factor] ->
    factor
    |> String.to_integer()
    |> Springs.run()

  _ ->
    IO.puts(:stderr, "Usage: #{:escript.script_name()} [fold factor] < input")
    exit({:shutdown, 1})
end
