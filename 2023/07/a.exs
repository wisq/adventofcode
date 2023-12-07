card_sort_keys =
  ~w{A K Q J T 9 8 7 6 5 4 3 2}
  |> Enum.with_index()
  |> Map.new()

IO.stream(:stdio, :line)
|> Enum.map(fn line ->
  [cards_text, bid_text] = String.split(line)
  cards = String.graphemes(cards_text)
  bid = String.to_integer(bid_text)

  sorted_freqs =
    cards
    |> Enum.frequencies()
    |> Map.values()
    |> Enum.sort(:desc)

  type_sort =
    case sorted_freqs do
      [5] -> 1
      [4, 1] -> 2
      [3, 2] -> 3
      [3, 1, 1] -> 4
      [2, 2, 1] -> 5
      [2, 1, 1, 1] -> 6
      [1, 1, 1, 1, 1] -> 7
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
