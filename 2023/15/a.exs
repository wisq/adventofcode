IO.read(:stdio, :eof)
|> String.trim()
|> String.split(",")
|> Enum.map(fn step ->
  step
  |> String.to_charlist()
  |> Enum.reduce(0, fn char, acc ->
    acc
    |> Kernel.+(char)
    |> Kernel.*(17)
    |> rem(256)
  end)
  |> IO.inspect(label: "Hash for #{inspect(step)}")
end)
|> Enum.sum()
|> IO.inspect(label: "Sum of hashes")
