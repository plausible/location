defmodule Location.City do
  @ets_table __MODULE__

  defstruct [:id, :name, :country_code]

  def load() do
    @ets_table =
      :ets.new(@ets_table, [
        :named_table,
        :public,
        :compressed,
        {:write_concurrency, true},
        {:read_concurrency, true}
      ])

    source_file()
    |> File.stream!()
    |> Stream.chunk_every(15_000)
    |> Task.async_stream(
      fn chunk ->
        chunk
        |> LocationCSV.parse_stream()
        |> Stream.map(fn [id, name, country_code] ->
          id = String.to_integer(id)
          country_code = String.trim(country_code)

          {id, {name, country_code}}
        end)
        |> Stream.each(fn chunk ->
          :ets.insert(@ets_table, chunk)
        end)
        |> Stream.run()
      end,
      timeout: :infinity
    )
    |> Stream.run()
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
    matchspec = [
      {{:"$1", {:"$2", :"$3"}}, [{:andalso, {:==, :"$2", name}, {:==, :"$3", country_code}}],
       [:"$1"]}
    ]

    case :ets.select(@ets_table, matchspec, 1) do
      {[id], _} -> to_struct(id, name, country_code)
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
