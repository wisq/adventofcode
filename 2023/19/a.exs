defmodule PartSorter do
  def run do
    [workflow_lines, part_lines] =
      IO.read(:stdio, :eof)
      |> String.split("\n\n")

    workflows =
      workflow_lines
      |> String.trim()
      |> String.split("\n")
      |> Enum.map(&parse_workflow/1)
      |> Map.new()

    part_lines
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&handle_part(&1, workflows))
    |> Enum.sum()
    |> IO.inspect(label: "Sum")
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
          [target] -> {fn _ -> true end, parse_target(target)}
        end
      end)

    {name, rules}
  end

  defp generate_condition(<<key::binary-size(1), ">", value::binary>>) do
    key = String.to_atom(key)
    value = String.to_integer(value)

    fn part ->
      Map.fetch!(part, key) > value
    end
  end

  defp generate_condition(<<key::binary-size(1), "<", value::binary>>) do
    key = String.to_atom(key)
    value = String.to_integer(value)

    fn part ->
      Map.fetch!(part, key) < value
    end
  end

  defp parse_target("A"), do: :accept
  defp parse_target("R"), do: :reject
  defp parse_target(str), do: str

  #
  # Part handling functions
  #

  defp handle_part(line, workflows) do
    line
    |> parse_part()
    |> run_workflow("in", workflows)
  end

  defp run_workflow(part, name, workflows) do
    rules = Map.fetch!(workflows, name)

    case match_rules(part, rules) do
      :accept ->
        IO.puts("Accepted by rule #{name}")
        score_part(part)

      :reject ->
        IO.puts("Rejected by rule #{name}")
        0

      target when is_binary(target) ->
        IO.puts("Continuing #{name} -> #{target} ...")
        run_workflow(part, target, workflows)
    end
  end

  defp parse_part(line) do
    line
    |> String.trim_leading("{")
    |> String.trim_trailing("}")
    |> String.split(",")
    |> Map.new(fn attr ->
      [key, value] = String.split(attr, "=")
      {String.to_atom(key), String.to_integer(value)}
    end)
    |> IO.inspect(label: "Parsed part")
  end

  defp score_part(part) do
    part
    |> Map.values()
    |> Enum.sum()
    |> IO.inspect(label: "Accepted")
  end

  defp match_rules(part, rules) do
    rules
    |> Enum.reduce_while(:no_match, fn {fun, target}, :no_match ->
      case fun.(part) do
        true -> {:halt, target}
        false -> {:cont, :no_match}
      end
    end)
  end
end

PartSorter.run()
