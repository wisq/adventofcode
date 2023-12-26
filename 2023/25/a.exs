defmodule Disco do
  def run do
    {nodes, connections} = load_data()
    graph = bidirectional_graph(connections)

    build_heatmap(nodes, graph)
    |> Enum.sort_by(fn {_, heat} -> -heat end)
    |> three_cut_permutations()
    |> Task.async_stream(fn cuts ->
      cuts_str = cuts |> Tuple.to_list() |> Enum.map(&inspect/1) |> Enum.join(" + ")

      case split_two_groups(cuts, nodes, graph) do
        {2, groups} ->
          sizes = groups |> Enum.map(&Enum.count/1)
          sizes_str = sizes |> Enum.join(" and ")
          IO.puts("Cutting #{cuts_str} gives two groups of size #{sizes_str}")
          raise "done"

        1 ->
          # IO.puts("Cutting #{cuts_str} does not split any groups")
          nil

        3 ->
          IO.puts("Cutting #{cuts_str} produces 3+ groups")
      end
    end)
    |> Stream.run()
  end

  defp load_data do
    node_data =
      IO.stream(:stdio, :line)
      |> Enum.map(fn line ->
        [name, others] = line |> String.split(":")

        {
          String.to_atom(name),
          others
          |> String.split()
          |> Enum.map(&String.to_atom/1)
        }
      end)

    nodes =
      node_data
      |> Enum.flat_map(fn {name, others} -> [name | others] end)
      |> MapSet.new()

    connections =
      node_data
      |> Enum.flat_map(fn {name, others} ->
        others
        |> Enum.map(&to_connection(name, &1))
      end)
      |> MapSet.new()

    {nodes, connections}
  end

  defp to_connection(a, b) when is_atom(a) and is_atom(b) do
    case a < b do
      true -> {a, b}
      false -> {b, a}
    end
  end

  defp bidirectional_graph(connections) do
    connections
    |> Enum.reduce(%{}, fn {from, to}, map ->
      map
      |> Map.update(from, [to], fn cs -> [to | cs] end)
      |> Map.update(to, [from], fn cs -> [from | cs] end)
    end)
  end

  defp build_heatmap(nodes, graph) do
    IO.puts("Building heatmap ...")

    nodes
    |> Task.async_stream(&heatmap_walk_paths([&1], %{}, graph))
    |> Enum.reduce(%{}, fn {:ok, hm_part}, heatmap ->
      Map.merge(heatmap, hm_part, fn _, a, b -> a + b end)
    end)
  end

  defp heatmap_walk_paths(todo, heatmap, graph, seen \\ MapSet.new()) do
    todo
    |> Enum.flat_map_reduce(heatmap, fn from, heatmap ->
      Map.fetch!(graph, from)
      |> Enum.reject(&(&1 in seen))
      |> Enum.map_reduce(heatmap, fn to, heatmap ->
        {
          to,
          Map.update(heatmap, to_connection(from, to), 1, &(&1 + 1))
        }
      end)
    end)
    |> then(fn
      {[], heatmap} ->
        heatmap

      {new_todo, heatmap} ->
        seen = MapSet.new(todo) |> MapSet.union(seen)
        heatmap_walk_paths(new_todo, heatmap, graph, seen)
    end)
  end

  defp three_cut_permutations(heatmap) do
    IO.puts("Generating permutations ...")

    Stream.resource(
      fn ->
        heatmap
        |> Enum.with_index()
        |> Enum.drop(2)
        |> :queue.from_list()
      end,
      fn queue ->
        case :queue.out(queue) do
          {{:value, {{a, _}, index}}, new_queue} ->
            above = Enum.take(heatmap, index)

            perms =
              for {b, _} <- above,
                  {c, _} <- above,
                  b < c,
                  do: {a, b, c}

            {perms, new_queue}

          {:empty, _} ->
            {:halt, nil}
        end
      end,
      fn _ -> nil end
    )
  end

  defp split_two_groups({_, _, _} = cuts, nodes, graph) do
    graph =
      cuts
      |> Tuple.to_list()
      |> Enum.reduce(graph, fn {a, b}, graph ->
        graph
        |> Map.update!(a, fn conns -> List.delete(conns, b) end)
        |> Map.update!(b, fn conns -> List.delete(conns, a) end)
      end)

    split_group(nodes, graph, 1)
  end

  defp split_group(nodes, graph, group_no, first_group \\ nil) do
    node = Enum.at(nodes, 0)
    {reachable, unreachable} = split_reachable(node, nodes, graph)

    case {group_no, Enum.empty?(unreachable)} do
      {1, true} -> 1
      {1, false} -> split_group(unreachable, graph, 2, reachable)
      {2, true} -> {2, [first_group, reachable]}
      {2, false} -> 3
    end
  end

  defp split_reachable(node, unseen, graph) do
    unseen = MapSet.delete(unseen, node)

    Map.fetch!(graph, node)
    |> Enum.flat_map_reduce(unseen, fn node, unseen ->
      case node in unseen do
        true -> split_reachable(node, unseen, graph)
        false -> {[], unseen}
      end
    end)
    |> then(fn {seen, unseen} -> {[node | seen], unseen} end)
  end
end

Disco.run()
