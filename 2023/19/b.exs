defmodule PartSorter do
  def run do
    [workflow_lines, _] =
      IO.read(:stdio, :eof)
      |> String.split("\n\n")

    workflows =
      workflow_lines
      |> String.trim()
      |> String.split("\n")
      |> Enum.map(&parse_workflow/1)
      |> Map.new()

    %{
      x: 1..4000,
      m: 1..4000,
      a: 1..4000,
      s: 1..4000
    }
    |> find_permutations("in", workflows)
    |> IO.inspect()
    |> Enum.map(fn part ->
      part
      |> Map.values()
      |> Enum.map(&Enum.count/1)
      |> Enum.product()
      |> IO.inspect(label: "Permutations for #{inspect(part)}")
    end)
    |> Enum.sum()
    |> IO.inspect(label: "Total permutations")
  end

  #
  # Workflow parsing functions
  #

  defp parse_workflow(line) do
    [name, rules] = String.split(line, "{")

    rules =
      rules
      |> String.trim_trailing("}")
      |> String.split(",")
      |> Enum.map(fn rule ->
        case String.split(rule, ":") do
          [condition, target] -> {generate_condition(condition), parse_target(target)}
          [target] -> {:all, parse_target(target)}
        end
      end)

    {name, rules}
  end

  defp generate_condition(<<key::binary-size(1), op, value::binary>>) when op in [?<, ?>] do
    key = String.to_atom(key)
    value = String.to_integer(value)

    op =
      case op do
        ?> -> :gt
        ?< -> :lt
      end

    {key, op, value}
  end

  defp parse_target("A"), do: :accept
  defp parse_target("R"), do: :reject
  defp parse_target(str), do: str

  #
  # Permutation functions
  #

  defp find_permutations(part, :accept, _), do: [part]
  defp find_permutations(_, :reject, _), do: []

  defp find_permutations(part, name, workflows) do
    workflows
    |> Map.fetch!(name)
    |> Enum.flat_map_reduce(part, &split_matching_part(&2, &1, workflows))
    |> then(fn {parts, nil} -> parts end)
  end

  defp split_matching_part(part, rule, workflows) do
    case rule do
      {{key, op, value}, target} ->
        {inside, outside} = Map.fetch!(part, key) |> split_range(op, value)

        {
          part
          |> Map.put(key, inside)
          |> find_permutations(target, workflows),
          part
          |> Map.put(key, outside)
        }

      {:all, target} ->
        {
          part |> find_permutations(target, workflows),
          nil
        }
    end
  end

  defp split_range(min..max, :gt, value) do
    {
      (value + 1)..max//1,
      min..value//1
    }
  end

  defp split_range(min..max, :lt, value) do
    {
      min..(value - 1)//1,
      value..max//1
    }
  end
end

PartSorter.run()
