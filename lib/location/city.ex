defmodule Location.City do
  @ets_table :geonames

  defstruct [:id, :name, :country_code]

  def load(heir) do
    tab = :binary.compile_pattern("\t")
    ets = :ets.new(@ets_table, [:named_table, :compressed, {:heir, heir, []}])

    File.stream!(source_file())
    |> Stream.map(&String.split(&1, tab))
    |> Enum.each(fn [id, name, country_code] ->
      id = String.to_integer(id)
      :ets.insert(ets, {id, {name, String.strip(country_code)}})
    end)
  end

  def get_city(id) do
    case :ets.lookup(@ets_table, id) do
      [{id, {name, country_code}}] -> to_struct(id, name, country_code)
      _ -> nil
    end
  end

  defp source_file() do
    lightweight_source_file = Application.app_dir(:location, "priv/geonames.lite.csv")
    Application.get_env(:location, :geonames_source_file, lightweight_source_file)
  end

  defp to_struct(id, name, country_code) do
    %__MODULE__{id: id, name: name, country_code: country_code}
  end
end
