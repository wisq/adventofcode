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

  sorted_freqs =
    cards
    |> Enum.reject(&(&1 == "J"))
    |> Enum.frequencies()
    |> Map.values()
    |> Enum.sort(:desc)

  type_sort =
    case {jokers, sorted_freqs} do
      # five of a kind
      {0, [5]} -> 1
      {1, [4]} -> 1
      {2, [3]} -> 1
      {3, [2]} -> 1
      {4, [1]} -> 1
      {5, []} -> 1
      # four of a kind
      {0, [4, 1]} -> 2
      {1, [3, 1]} -> 2
      {2, [2, 1]} -> 2
      {3, [1, 1]} -> 2
      # full house
      {0, [3, 2]} -> 3
      {1, [2, 2]} -> 3
      # three of a kind
      {0, [3, 1, 1]} -> 4
      {1, [2, 1, 1]} -> 4
      {2, [1, 1, 1]} -> 4
      # two pair
      {0, [2, 2, 1]} -> 5
      # one pair
      {0, [2, 1, 1, 1]} -> 6
      {1, [1, 1, 1, 1]} -> 6
      # high card
      {0, [1, 1, 1, 1, 1]} -> 7
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
