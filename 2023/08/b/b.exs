defmodule Walker do
  defmodule State do
    @enforce_keys [:directions]
    defstruct(
      ghosts: [],
      directions: nil,
      pending_turns: [],
      node_map: %{},
      steps: 0
    )
  end

  def run do
    IO.stream(:stdio, :line)
    |> Stream.map(&String.trim/1)
    |> Enum.reduce(:start, &handle_input/2)
    |> populate_ghosts()
    |> IO.inspect(label: "Loaded")
    |> move_until_done()
    |> IO.inspect(label: "Final state")
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

  defp populate_ghosts(state) do
    %State{
      state
      | ghosts:
          state.node_map
          |> Map.keys()
          |> Enum.filter(fn
            <<_, _, ?A>> -> true
            <<_, _, _>> -> false
          end)
    }
  end

  defp move_until_done(state) do
    state
    |> move_once()
    |> then(fn state ->
      case state.ghosts
           |> Enum.all?(fn
             <<_, _, ?Z>> -> true
             <<_, _, _>> -> false
           end) do
        true -> state
        false -> move_until_done(state)
      end
    end)
  end

  defp move_once(state) do
    # IO.inspect(state.ghosts, label: "move_once")
    {turn, state} = next_turn(state)

    %State{
      state
      | ghosts:
          state.ghosts
          |> Enum.map(fn node ->
            Map.fetch!(state.node_map, node)
            |> elem(turn)
          end)
    }
  end

  defp next_turn(%State{pending_turns: []} = state) do
    %State{state | pending_turns: state.directions}
    |> next_turn()
  end

  defp next_turn(%State{pending_turns: [turn | rest], steps: steps} = state) do
    {turn, %State{state | pending_turns: rest, steps: steps + 1}}
  end
end

Walker.run()
