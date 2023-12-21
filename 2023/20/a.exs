defmodule Pulses do
  defmodule Broadcaster do
    @enforce_keys [:targets]
    defstruct(@enforce_keys)
  end

  defmodule FlipFlop do
    @enforce_keys [:targets]
    defstruct(
      targets: nil,
      on: false
    )
  end

  defmodule Conjunction do
    @enforce_keys [:targets]
    defstruct(
      targets: nil,
      memory: %{}
    )
  end

  defmodule State do
    @enforce_keys [:layout]
    defstruct(
      layout: nil,
      pending: :queue.new(),
      lows: 0,
      highs: 0
    )
  end

  def run do
    layout =
      parse_layout()
      |> populate_memory()
      |> IO.inspect()

    1..1000
    |> Enum.map_reduce(layout, fn n, layout ->
      state = layout |> push_button()
      result = {state.highs, state.lows}

      {result, state.layout}
    end)
    |> then(fn {counts, _} -> counts end)
    |> Enum.reduce(fn {h1, l1}, {h2, l2} -> {h1 + h2, l1 + l2} end)
    |> IO.inspect(label: "Highs and lows")
    |> Tuple.to_list()
    |> Enum.product()
    |> IO.inspect(label: "Product")
  end

  defp parse_layout do
    IO.stream(:stdio, :line)
    |> Map.new(fn line ->
      line
      |> String.trim()
      |> parse_module()
    end)
  end

  defp parse_module("broadcaster -> " <> targets) do
    {:broadcaster,
     %Broadcaster{
       targets: targets |> parse_targets()
     }}
  end

  defp parse_module("%" <> flipflop) do
    [name, targets] = String.split(flipflop, " -> ")

    {name |> String.to_atom(),
     %FlipFlop{
       targets: targets |> parse_targets()
     }}
  end

  defp parse_module("&" <> conjunction) do
    [name, targets] = String.split(conjunction, " -> ")

    {name |> String.to_atom(),
     %Conjunction{
       targets: targets |> parse_targets()
     }}
  end

  defp parse_targets(targets) do
    targets
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.to_atom/1)
  end

  defp populate_memory(layout) do
    layout
    |> Map.new(fn {name, module} ->
      {name, populate(name, module, layout)}
    end)
  end

  defp populate(name, %Conjunction{} = module, layout) do
    memory =
      layout
      |> Enum.filter(fn {_, %{targets: targets}} -> name in targets end)
      |> Map.new(fn {n, _} -> {n, :low} end)

    %Conjunction{module | memory: memory}
  end

  defp populate(name, module, _layout), do: module

  def push_button(layout) do
    %State{layout: layout}
    |> send_pulse(:button, :low, [:broadcaster])
    |> execute_pending()
  end

  defp send_pulse(state, source, type, targets) do
    count = Enum.count(targets)

    state =
      case type do
        :low -> %State{state | lows: state.lows + count}
        :high -> %State{state | highs: state.highs + count}
      end

    event = {source, type, targets}
    pending = :queue.in(event, state.pending)
    %State{state | pending: pending}
  end

  defp execute_pending(state) do
    pending = :queue.to_list(state.pending)
    state = %State{state | pending: :queue.new()}

    pending
    |> Enum.reduce(state, fn {source, type, targets}, state ->
      targets
      |> Enum.reduce(state, fn target, state ->
        case Map.fetch(state.layout, target) do
          {:ok, module} -> %State{} = handle_pulse(state, module, target, source, type)
          :error -> state
        end
      end)
    end)
    |> then(fn state ->
      case :queue.is_empty(state.pending) do
        true -> state
        false -> execute_pending(state)
      end
    end)
  end

  defp handle_pulse(
         state,
         %Broadcaster{} = module,
         :broadcaster = name,
         :button = source,
         :low = type
       ) do
    state
    |> send_pulse(name, type, module.targets)
  end

  defp handle_pulse(state, %FlipFlop{} = module, _name, _source, :high) do
    state
  end

  defp handle_pulse(state, %FlipFlop{on: on} = module, name, _source, :low) do
    state
    |> update_module(name, %FlipFlop{module | on: !on})
    |> send_pulse(
      name,
      case on do
        false -> :high
        true -> :low
      end,
      module.targets
    )
  end

  defp handle_pulse(state, %Conjunction{} = module, name, source, type) do
    module = %Conjunction{module | memory: Map.put(module.memory, source, type)}

    state
    |> update_module(name, module)
    |> send_pulse(
      name,
      case module.memory |> Enum.all?(fn {_src, t} -> t == :high end) do
        true -> :low
        false -> :high
      end,
      module.targets
    )
  end

  defp update_module(state, name, module) do
    layout = state.layout |> Map.put(name, module)
    %State{state | layout: layout}
  end
end

Pulses.run()
