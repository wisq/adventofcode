card_sort_keys =
  ~w{A K Q T 9 8 7 6 5 4 3 2 J}
  |> Enum.with_index()
  |> Map.new()

IO.stream(:stdio, :line)
|> Enum.map(fn line ->
  [cards_text, bid_text] = String.split(line)
  cards = String.graphemes(cards_text)
  bid = String.to_integer(bid_text)

  jokers = cards |> Enum.count(&(&1 == "J"))

  sorted_groups =
    cards
    |> Enum.reject(&(&1 == "J"))
    |> Enum.group_by(& &1)
    |> Map.values()
    |> Enum.sort_by(&(-Enum.count(&1)))

  type_sort =
    case {jokers, sorted_groups} do
      # five of a kind
      {0, [[a, a, a, a, a]]} -> 1
      {1, [[a, a, a, a]]} -> 1
      {2, [[a, a, a]]} -> 1
      {3, [[a, a]]} -> 1
      {4, [[_]]} -> 1
      {5, []} -> 1
      # four of a kind
      {0, [[a, a, a, a], [_]]} -> 2
      {1, [[a, a, a], [_]]} -> 2
      {2, [[a, a], [_]]} -> 2
      {3, [[_], [_]]} -> 2
      # full house
      {0, [[a, a, a], [b, b]]} -> 3
      {1, [[a, a], [b, b]]} -> 3
      # three of a kind
      {0, [[a, a, a], [_], [_]]} -> 4
      {1, [[a, a], [_], [_]]} -> 4
      {2, [[_], [_], [_]]} -> 4
      # two pair
      {0, [[a, a], [b, b], [_]]} -> 5
      # one pair
      {0, [[a, a], [_], [_], [_]]} -> 6
      {1, [[_], [_], [_], [_]]} -> 6
      # high card
      {0, [[_], [_], [_], [_], [_]]} -> 7
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
