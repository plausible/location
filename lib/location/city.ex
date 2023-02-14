defmodule Location.City do
  @ets_table :geonames
  @ets_table_by_label :geonames_by_label

  defstruct [:id, :name, :country_code]

  def load(heir) do
    :ets.new(@ets_table, [:named_table, :compressed, {:heir, heir, []}])
    :ets.new(@ets_table_by_label, [:named_table, :compressed, {:heir, heir, []}])

    tab = :binary.compile_pattern("\t")

    File.stream!(source_file())
    |> Stream.map(&String.split(&1, tab))
    |> Enum.each(fn [id, name, country_code] ->
      id = String.to_integer(id)
      country_code = String.trim(country_code)

      :ets.insert(@ets_table, {id, {name, country_code}})
      :ets.insert(@ets_table_by_label, {{name, country_code}, id})
    end)
  end

  @doc """
  Finds city by GeoNames ID.
  """
  @spec get_city(integer()) :: %__MODULE__{} | nil
  def get_city(id) do
    case :ets.lookup(@ets_table, id) do
      [{id, {name, country_code}}] -> to_struct(id, name, country_code)
      _ -> nil
    end
  end

  @doc """
  Finds city by name and country code.

  This function returns the first city found when the country has multiple
  cities with the same name.
  """
  @spec get_city(String.t(), String.t()) :: %__MODULE__{} | nil
  def get_city(name, country_code) do
    case :ets.lookup(@ets_table_by_label, {name, country_code}) do
      [{{name, country_code}, id}] -> to_struct(id, name, country_code)
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
