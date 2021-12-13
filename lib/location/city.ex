defmodule Location.City do
  @ets_table :geonames

  defstruct [:id, :name, :country_code]

  def load(heir) do
    tab = :binary.compile_pattern("\t")
    ets = :ets.new(@ets_table, [:named_table, {:heir, heir, []}])

    File.stream!(source_file())
    |> Stream.map(&String.split(&1, tab))
    |> Enum.each(fn [id, name, country_code] ->
      id = String.to_integer(id)
      country_code = String.trim(country_code)
      :ets.insert(ets, {id, %__MODULE__{id: id, name: name, country_code: country_code}})
    end)
  end

  def search_city(search_phrase) do
    search_phrase = String.downcase(search_phrase)

    :ets.foldl(fn
      {_code, entry}, acc ->
        if String.starts_with?(String.downcase(entry.name), search_phrase) do
          [entry | acc]
        else
          acc
        end
    end, [], @ets_table)
  end

  def get_city(id) do
    case :ets.lookup(@ets_table, id) do
      [{_, entry}] -> entry
      _ -> nil
    end
  end

  defp source_file() do
    lightweight_source_file = Application.app_dir(:location, "priv/geonames.lite.csv")
    Application.get_env(:location, :geonames_source_file, lightweight_source_file)
  end
end
