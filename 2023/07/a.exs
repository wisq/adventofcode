card_sort_keys =
  ~w{A K Q J T 9 8 7 6 5 4 3 2}
  |> Enum.with_index()
  |> Map.new()

IO.stream(:stdio, :line)
|> Enum.map(fn line ->
  [cards_text, bid_text] = String.split(line)
  cards = String.graphemes(cards_text)
  bid = String.to_integer(bid_text)

  sorted_groups =
    cards
    |> Enum.group_by(& &1)
    |> Map.values()
    |> Enum.sort_by(&(-Enum.count(&1)))

  type_sort =
    case sorted_groups do
      [[a, a, a, a, a]] -> 1
      [[a, a, a, a], [_]] -> 2
      [[a, a, a], [b, b]] -> 3
      [[a, a, a], [_], [_]] -> 4
      [[a, a], [b, b], [_]] -> 5
      [[a, a], [_], [_], [_]] -> 6
      [[_], [_], [_], [_], [_]] -> 7
    end

  card_sort = cards |> Enum.map(&Map.fetch!(card_sort_keys, &1))

  {type_sort, card_sort, bid}
  |> IO.inspect(label: cards_text, charlists: :as_list)
end)
|> Enum.sort()
|> IO.inspect(label: "Hands, strongest to weakest")
|> Enum.reverse()
|> Enum.with_index(1)
|> Enum.map(fn {{_, _, bid}, rank} -> bid * rank end)
|> Enum.sum()
|> IO.inspect(label: "Winnings")
