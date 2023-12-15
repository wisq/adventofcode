defmodule Lenses do
  def run do
    IO.read(:stdio, :eof)
    |> String.trim()
    |> String.split(",")
    |> Enum.map(&parse_step/1)
    |> Enum.reduce(%{}, &handle_step/2)
    |> IO.inspect(label: "Final boxes")
    |> Enum.sort()
    |> Enum.map(fn {box, lenses} ->
      lenses
      |> Enum.with_index(1)
      |> Enum.map(fn {{_label, focal}, index} ->
        (box + 1) * index * focal
      end)
      |> Enum.sum()
      |> IO.inspect(label: "Power of box #{box}")
    end)
    |> Enum.sum()
    |> IO.inspect(label: "Total sum")
  end

  @step_regex ~r/^([a-z]+)(-|(=)(\d+))$/

  defp parse_step(step) do
    case Regex.run(@step_regex, step) do
      [_, label, "-"] -> {:remove, label}
      [_, label, _, "=", focal] -> {:add, label, String.to_integer(focal)}
    end
  end

  defp handle_step({:add, label, focal}, boxes) do
    boxes
    |> Map.update(
      hash(label),
      [{label, focal}],
      &List.keystore(&1, label, 0, {label, focal})
    )
  end

  defp handle_step({:remove, label}, boxes) do
    boxes
    |> Map.update(
      hash(label),
      [],
      &List.keydelete(&1, label, 0)
    )
  end

  defp hash(word) do
    word
    |> String.to_charlist()
    |> Enum.reduce(0, fn char, acc ->
      acc
      |> Kernel.+(char)
      |> Kernel.*(17)
      |> rem(256)
    end)
  end
end

Lenses.run()
