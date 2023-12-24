defmodule Hailstorm do
  defmodule Stone do
    @enforce_keys [:id, :x, :y, :z, :vx, :vy, :vz]
    defstruct(@enforce_keys)
  end

  def run(range) do
    IO.stream(:stdio, :line)
    |> Enum.with_index(1)
    |> Enum.map(fn {line, index} ->
      [[x, y, z], [vx, vy, vz]] =
        line
        |> String.trim()
        |> String.split("@")
        |> Enum.map(fn part ->
          part
          |> String.split(",")
          |> Enum.map(fn int ->
            int
            |> String.trim()
            |> String.to_integer()
          end)
        end)

      id = index |> Integer.to_string() |> String.pad_leading(3, "0")
      %Stone{id: id, x: x, y: y, z: z, vx: vx, vy: vy, vz: vz}
    end)
    |> find_all_intercepts(range)
    |> IO.inspect(label: "Interceptions")
  end

  defp find_all_intercepts(stones, range) do
    stones
    |> all_pairs()
    |> Enum.count(fn {a, b} ->
      case find_intercept(a, b) do
        {{x, y} = pos, :future, :future} ->
          (in_range(x, range) and in_range(y, range))
          |> IO.inspect(label: "Stone #{a.id} intercepts #{b.id} at #{inspect(pos)} in range")

        {pos, _, _} ->
          IO.puts("Stone #{a.id} already intercepted #{b.id} at #{inspect(pos)}")
          false

        :parallel ->
          IO.puts("Stone #{a.id} is parallel with #{b.id}")
          false
      end
    end)
  end

  defp all_pairs(list) do
    list
    |> Enum.with_index()
    |> Enum.flat_map(fn {a, index} ->
      list
      |> Enum.drop(index + 1)
      |> Enum.map(fn b ->
        {a, b}
      end)
    end)
  end

  # from https://www.cuemath.com/geometry/intersection-of-two-lines/
  # with b term simplified to 1
  defp find_intercept(a, b) do
    mA = a.vy / a.vx
    mB = b.vy / b.vx

    a1 = mA
    c1 = a.y - mA * a.x

    a2 = mB
    c2 = b.y - mB * b.x

    case a1 == a2 do
      true ->
        :parallel

      false ->
        x0 = (c2 - c1) / (a1 - a2)
        # I honestly don't know why I need to sign-invert this,
        # but I was reliably getting the wrong sign, so.
        y0 = 0 - (c1 * a2 - c2 * a1) / (a1 - a2)
        {x0, y0} |> with_intercept_time(a, b)
    end
  end

  defp with_intercept_time({x0, y0} = intercept, a, b) do
    # x0 = x + vx*t
    # -vx*t = x - x0
    # t = (x - x0)/-vx
    ta = (a.x - x0) / -a.vx
    tb = (b.x - x0) / -b.vx

    {
      intercept,
      case ta < 0 do
        true -> :past
        false -> :future
      end,
      case tb < 0 do
        true -> :past
        false -> :future
      end
    }
  end

  defp in_range(n, min..max) do
    n >= min && n <= max
  end
end

case System.argv() do
  [range] ->
    [min, max] = range |> String.split("..") |> Enum.map(&String.to_integer/1)
    Hailstorm.run(min..max)

  _ ->
    IO.puts(:stderr, "Usage: #{:escript.script_name()} <min..max> < input")
    exit({:shutdown, 1})
end
