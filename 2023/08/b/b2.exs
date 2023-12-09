defmodule Walker do
  defmodule State do
    @enforce_keys [:directions]
    defstruct(
      directions: nil,
      node_map: %{}
    )
  end

  defmodule GhostState do
    @enforce_keys [:starting_node, :node]
    defstruct(
      starting_node: nil,
      node: nil,
      steps: 0,
      end_nodes: %{}
    )
  end

  def run do
    IO.stream(:stdio, :line)
    |> Stream.map(&String.trim/1)
    |> Enum.reduce(:start, &handle_input/2)
    |> IO.inspect(label: "Loaded")
    |> walk_ghosts()
    |> IO.inspect(label: "Walked ghosts")
    |> Enum.map(&cycle_length/1)
    |> IO.inspect(label: "Cycle lengths")
    |> Enum.reduce(&lcm/2)
    |> IO.inspect(label: "LCM")
  end

  defp handle_input(directions, :start) do
    %State{
      directions:
        directions
        |> String.graphemes()
        |> Enum.map(fn
          "L" -> 0
          "R" -> 1
        end)
    }
  end

  defp handle_input("", state), do: state

  defp handle_input(
         <<node::binary-size(3), " = (", left::binary-size(3), ", ", right::binary-size(3), ")">>,
         state
       ) do
    state
    |> add_node_map(node, left, right)
  end

  defp add_node_map(%State{} = state, node, left, right) do
    %State{
      state
      | node_map: state.node_map |> Map.put(node, {left, right})
    }
  end

  defp walk_ghosts(state) do
    state.node_map
    |> Map.keys()
    |> Enum.filter(fn
      <<_, _, ?A>> -> true
      <<_, _, _>> -> false
    end)
    |> Enum.map(fn node ->
      %GhostState{starting_node: node, node: node}
      |> walk_one_ghost(state)
    end)
  end

  defp walk_one_ghost(ghost, state) do
    state.directions
    |> Stream.with_index()
    |> Stream.cycle()
    |> Enum.reduce_while(ghost, &ghost_walk(&1, &2, state.node_map))
  end

  defp ghost_walk({turn, dirs_index}, ghost, node_map) do
    Map.fetch!(node_map, ghost.node)
    |> elem(turn)
    |> handle_next_node(dirs_index, ghost)
  end

  defp handle_next_node(<<_, _, ?Z>> = node, dirs_index, ghost) do
    ghost = %GhostState{ghost | node: node, steps: ghost.steps + 1}

    ghost.end_nodes
    |> Map.update(
      node,
      {:seen_once, dirs_index, ghost.steps},
      fn
        {:seen_once, ^dirs_index, old_steps} ->
          {:seen_twice, dirs_index, old_steps, ghost.steps}
      end
    )
    |> then(fn end_nodes ->
      cont_or_halt =
        end_nodes
        |> Map.values()
        |> Enum.all?(fn
          {:seen_once, _, _} -> false
          {:seen_twice, _, _, _} -> true
        end)
        |> then(fn
          false -> :cont
          true -> :halt
        end)

      {cont_or_halt, %GhostState{ghost | end_nodes: end_nodes}}
    end)
  end

  defp handle_next_node(<<_, _, _>> = node, _, ghost) do
    {:cont, %GhostState{ghost | node: node, steps: ghost.steps + 1}}
  end

  defp cycle_length(ghost) do
    [{:seen_twice, _, steps1, steps2}] = ghost.end_nodes |> Map.values()
    steps2 - steps1
  end

  defp lcm(a, b) do
    div(a * b, Integer.gcd(a, b))
  end
end

Walker.run()
