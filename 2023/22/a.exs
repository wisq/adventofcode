defmodule Stacker do
  def run do
    bricks = parse_bricks()
    world = bricks |> Enum.reduce(&MapSet.union/2)

    {bricks, world} = fall_until_stable(bricks, world)

    count_zappable(bricks, world)
    |> IO.inspect(label: "Zappable bricks")
  end

  def parse_bricks do
    IO.stream(:stdio, :line)
    |> Enum.map(fn line ->
      line
      |> String.trim()
      |> String.split("~")
      |> Enum.map(fn coords ->
        coords
        |> String.split(",")
        |> Enum.map(&String.to_integer/1)
        |> then(fn [x, y, z] -> {x, y, z} end)
      end)
      |> then(fn [head, tail] ->
        brick_coords(head, tail)
        |> MapSet.new()
      end)
    end)
    |> MapSet.new()
  end

  defp brick_coords({x, y, z}, {x, y, z}), do: [{x, y, z}]
  defp brick_coords({x1, y, z}, {x2, y, z}), do: x1..x2 |> Enum.map(fn x -> {x, y, z} end)
  defp brick_coords({x, y1, z}, {x, y2, z}), do: y1..y2 |> Enum.map(fn y -> {x, y, z} end)
  defp brick_coords({x, y, z1}, {x, y, z2}), do: z1..z2 |> Enum.map(fn z -> {x, y, z} end)

  defp fall_until_stable(bricks, world) do
    IO.puts("Falling ...")

    case fall_once(bricks, world) do
      {^bricks, ^world} -> {bricks, world}
      {bricks, world} -> fall_until_stable(bricks, world)
    end
  end

  defp fall_once(bricks, world) do
    bricks
    |> Enum.map_reduce(world, &attempt_fall/2)
    |> then(fn {bricks, world} ->
      {MapSet.new(bricks), world}
    end)
  end

  defp attempt_fall(brick, world) do
    {footprint, z} = get_footprint(brick)

    stop_at =
      z..1//-1
      |> Enum.find(fn
        1 -> true
        z -> footprint |> Enum.any?(fn {x, y} -> {x, y, z - 1} in world end)
      end)

    case stop_at do
      ^z -> {brick, world}
      new_z -> drop_brick(brick, z - new_z, world)
    end
  end

  defp get_footprint(brick) do
    lowest_z =
      brick
      |> Enum.map(fn {_, _, z} -> z end)
      |> Enum.min()

    footprint =
      brick
      |> Enum.filter(fn {_, _, z} -> z == lowest_z end)
      |> Enum.map(fn {x, y, ^lowest_z} -> {x, y} end)

    {footprint, lowest_z}
  end

  defp drop_brick(old_brick, by_z, old_world) do
    IO.puts("Dropping #{inspect(old_brick)} by #{by_z} blocks")

    new_brick =
      old_brick
      |> Enum.map(fn {x, y, z} -> {x, y, z - by_z} end)
      |> MapSet.new()

    new_world =
      old_world
      |> MapSet.difference(old_brick)
      |> MapSet.union(new_brick)

    {new_brick, new_world}
  end

  defp count_zappable(bricks, world) do
    IO.puts("Counting zappable bricks ...")

    bricks
    |> Enum.count(&can_zap?(&1, bricks, world))
  end

  defp can_zap?(brick, bricks, world) do
    IO.puts("Zapping brick #{inspect(brick)} ...")
    bricks = MapSet.delete(bricks, brick)
    world = MapSet.difference(world, brick)

    case fall_once(bricks, world) do
      {^bricks, ^world} -> true
      {_, _} -> false
    end
  end
end

Stacker.run()
