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
  [cards_text, bid_text] = String.split(line)
  cards = String.graphemes(cards_text)
  bid = String.to_integer(bid_text)

  {jokers, non_jokers} = cards |> Enum.split_with(is_joker)

  sorted_freqs =
    non_jokers
    |> Enum.frequencies()
    |> Map.values()
    |> Enum.sort(:desc)
    |> List.update_at(0, fn c -> c + Enum.count(jokers) end)

  type_sort =
    case sorted_freqs do
      # special case: all jokers
      [] -> 1
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
|> IO.inspect(label: "Hands, strongest to weakest", charlists: :as_list)
|> Enum.reverse()
|> Enum.with_index(1)
|> Enum.map(fn {{_, _, bid}, rank} -> bid * rank end)
|> Enum.sum()
|> IO.inspect(label: "Winnings")
