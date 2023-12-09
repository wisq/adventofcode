defmodule Walker do
  defmodule State do
    @enforce_keys [:directions, :waiting_for_node]
    defstruct(
      directions: nil,
      pending_turns: [],
      waiting_for_node: nil,
      node_map: %{},
      steps: 0
    )
  end

  def run do
    IO.stream(:stdio, :line)
    |> Stream.map(&String.trim/1)
    |> Enum.reduce(:start, &handle_input/2)
    |> IO.inspect(label: "Final state")
  end

  defp handle_input(directions, :start) do
    %State{
      waiting_for_node: "AAA",
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
    |> maybe_move(node)
  end

  defp add_node_map(%State{} = state, node, left, right) do
    %State{
      state
      | node_map: state.node_map |> Map.put(node, {left, right})
    }
  end

  defp maybe_move(%State{waiting_for_node: node} = state, node), do: move_recursive(state)
  defp maybe_move(state, _node), do: state

  defp move_recursive(%State{waiting_for_node: "ZZZ"} = state), do: state

  defp move_recursive(state) do
    node = state.waiting_for_node
    {turn, turned_state} = next_turn(state)

    case Map.fetch(state.node_map, node) do
      {:ok, {_, _} = targets} ->
        %State{turned_state | waiting_for_node: elem(targets, turn)}
        |> move_recursive()

      :error ->
        state
    end
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
