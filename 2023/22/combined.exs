defmodule Stacker do
  defmodule Brick do
    @enforce_keys [:id, :coords, :footprint, :lowest_z]
    defstruct(@enforce_keys)
  end

  def run do
    bricks = parse_bricks()
    world = bricks |> Enum.map(& &1.coords) |> Enum.reduce(&MapSet.union/2)

    {bricks, world} = fall_until_stable(bricks, world)
    zap_drops = count_zap_drops(bricks, world)

    zap_drops
    |> Enum.filter(&(&1 == 0))
    |> Enum.count()
    |> IO.inspect(label: "Safely zappable bricks")

    zap_drops
    |> Enum.sum()
    |> IO.inspect(label: "Zap chain reactions")
  end

  def parse_bricks do
    IO.stream(:stdio, :line)
    |> Enum.with_index(1)
    |> Enum.map(fn {line, index} ->
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
        coords = brick_coords(head, tail)
        {footprint, lowest_z} = get_footprint(coords)

        %Brick{
          id: index |> Integer.to_string() |> String.pad_leading(4, "0"),
          coords: coords |> MapSet.new(),
          footprint: footprint,
          lowest_z: lowest_z
        }
      end)
    end)
    |> MapSet.new()
  end

  defp brick_coords({x, y, z}, {x, y, z}), do: [{x, y, z}]
  defp brick_coords({x1, y, z}, {x2, y, z}), do: x1..x2 |> Enum.map(fn x -> {x, y, z} end)
  defp brick_coords({x, y1, z}, {x, y2, z}), do: y1..y2 |> Enum.map(fn y -> {x, y, z} end)
  defp brick_coords({x, y, z1}, {x, y, z2}), do: z1..z2 |> Enum.map(fn z -> {x, y, z} end)

  defp fall_until_stable(bricks, world) do
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

  defp attempt_fall(%Brick{} = brick, world) do
    z = brick.lowest_z

    stop_at =
      z..1//-1
      |> Enum.find(fn
        1 -> true
        z -> brick.footprint |> Enum.any?(fn {x, y} -> {x, y, z - 1} in world end)
      end)

    case stop_at do
      ^z -> {brick, world}
      new_z -> drop_brick(brick, z - new_z, world)
    end
  end

  defp get_footprint(coords) do
    lowest_z =
      coords
      |> Enum.map(fn {_, _, z} -> z end)
      |> Enum.min()

    footprint =
      coords
      |> Enum.filter(fn {_, _, z} -> z == lowest_z end)
      |> Enum.map(fn {x, y, ^lowest_z} -> {x, y} end)

    {footprint, lowest_z}
  end

  defp drop_brick(%Brick{} = old_brick, by_z, old_world) do
    # IO.puts("Dropping #{old_brick.id} by #{by_z} blocks")

    new_brick =
      %Brick{
        old_brick
        | coords:
            old_brick.coords
            |> Enum.map(fn {x, y, z} -> {x, y, z - by_z} end)
            |> MapSet.new(),
          lowest_z: old_brick.lowest_z - by_z
      }

    new_world =
      old_world
      |> MapSet.difference(old_brick.coords)
      |> MapSet.union(new_brick.coords)

    {new_brick, new_world}
  end

  defp count_zap_drops(bricks, world) do
    IO.puts("Counting zappable bricks & their respective drops ...")

    bricks
    |> Enum.sort_by(& &1.id)
    |> Enum.map(&count_brick_zap_drops(&1, bricks, world))
  end

  defp count_brick_zap_drops(brick, bricks, world) do
    IO.puts("Zapping brick #{brick.id} ...")
    bricks = MapSet.delete(bricks, brick)
    world = MapSet.difference(world, brick.coords)

    case fall_until_stable(bricks, world) do
      {^bricks, ^world} ->
        0

      {new_bricks, _} ->
        MapSet.difference(bricks, new_bricks)
        |> Enum.count()
    end
  end
end

Stacker.run()
