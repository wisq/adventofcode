with_jokers =
  case System.argv() do
    [] -> false
    ["--jokers"] -> true
    _ -> raise "Usage: #{:escript.script_name()} [--jokers] < input"
  end

card_sort_keys =
  case with_jokers do
    false -> ~w{A K Q J T 9 8 7 6 5 4 3 2}
    true -> ~w{A K Q T 9 8 7 6 5 4 3 2 J}
  end
  |> Enum.reverse()
  |> Enum.with_index()
  |> Map.new()

is_joker =
  case with_jokers do
    false ->
      fn _ -> false end

    true ->
      fn
        "J" -> true
        _ -> false
      end
  end

IO.stream(:stdio, :line)
|> Enum.map(fn line ->
  [cards_str, bid] = String.split(line)
  {cards_str, String.to_integer(bid)}
end)
|> Enum.sort_by(fn {cards_str, _} ->
  cards = String.graphemes(cards_str)

  {jokers, non_jokers} = cards |> Enum.split_with(is_joker)

  sorted_freqs =
    non_jokers
    |> Enum.frequencies()
    |> Map.values()
    |> Enum.sort(:desc)
    |> List.update_at(0, fn c -> c + Enum.count(jokers) end)
    |> then(fn
      # special case: all jokers
      [] -> [5]
      list -> list
    end)

  high_card_sort = cards |> Enum.map(&Map.fetch!(card_sort_keys, &1))

  {sorted_freqs, high_card_sort}
  |> IO.inspect(label: cards_str, charlists: :as_list)
end)
|> IO.inspect(label: "Hands, weakest to strongest")
|> Enum.with_index(1)
|> Enum.map(fn {{_, bid}, rank} -> bid * rank end)
|> Enum.sum()
|> IO.inspect(label: "Winnings")
