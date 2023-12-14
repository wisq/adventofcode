IO.read(:stdio, :eof)
|> String.trim()
|> String.split("\n")
|> Enum.map(&String.to_charlist/1)
|> Enum.zip()
|> Enum.with_index(1)
|> Enum.map(fn {t, column} ->
  t
  |> Tuple.to_list()
  |> Enum.chunk_by(fn
    ?# -> :block
    ?O -> :roll
    ?. -> :roll
  end)
  |> Enum.map(fn chunk ->
    chunk
    |> Enum.sort_by(fn
      ?# -> -1
      ?O -> 0
      ?. -> 1
    end)
  end)
  |> List.flatten()
  |> Enum.reverse()
  |> Enum.with_index(1)
  |> Enum.map(fn
    {?#, _} -> 0
    {?., _} -> 0
    {?O, i} -> i
  end)
  |> Enum.sum()
  |> IO.inspect(label: "Load for column #{column}")
end)
|> Enum.sum()
|> IO.inspect(label: "Load")
