defmodule Location.City do
  @ets_table_by_id __MODULE__
  @ets_table_by_label Module.concat(__MODULE__, ByLabel)

  defstruct [:id, :name, :country_code]

  def load() do
    @ets_table_by_id =
      :ets.new(@ets_table_by_id, [
        :set,
        :named_table,
        :public,
        :compressed,
        {:write_concurrency, true},
        {:read_concurrency, true},
        {:decentralized_counters, false}
      ])

    @ets_table_by_label =
      :ets.new(@ets_table_by_label, [
        :set,
        :named_table,
        :public,
        :compressed,
        {:write_concurrency, true},
        {:read_concurrency, true},
        {:decentralized_counters, false}
      ])

    source_file()
    |> File.stream!()
    |> Stream.chunk_every(15_000)
    |> Task.async_stream(
      fn chunk ->
        chunk
        |> LocationCSV.parse_stream()
        |> Stream.each(fn [id, name, country_code] ->
          id = String.to_integer(id)
          country_code = String.trim(country_code)

          true = :ets.insert(@ets_table_by_id, {id, {name, country_code}})
          true = :ets.insert(@ets_table_by_label, {{name, country_code}, id})
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
    case :ets.lookup(@ets_table_by_id, id) do
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
