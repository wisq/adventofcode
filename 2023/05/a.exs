IO.read(:stdio, :eof)
|> String.trim()
|> String.split("\n\n")
|> Enum.reduce(nil, fn
  "seeds: " <> seeds, nil ->
    seeds
    |> String.split()
    |> Enum.map(&String.to_integer/1)
    |> IO.inspect(label: "Loaded seeds")

  section_text, id_list ->
    [header | map_rows] = section_text |> String.split("\n")
    [_, from, to] = Regex.run(~r/^(\w+)-to-(\w+) map:$/, header)

    mapping =
      map_rows
      |> Enum.map(fn line ->
        line
        |> String.split(" ", parts: 3)
        |> Enum.map(&String.to_integer/1)
      end)

    id_list
    |> Enum.map(fn id ->
      mapping
      |> Enum.reduce_while(id, fn [out_start, in_start, size], _ ->
        offset = id - in_start

        if offset >= 0 && offset <= size do
          {:halt, out_start + offset}
        else
          {:cont, id}
        end
      end)
    end)
    |> IO.inspect(label: "Mapped #{from} -> #{to}", charlists: :as_lists)
end)
|> Enum.min()
|> IO.inspect(label: "Lowest location")
