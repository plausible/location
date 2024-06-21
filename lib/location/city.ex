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

  def async_load_map do
    task =
      Task.async(fn ->
        csv = File.read!(source_file())
        parsed_csv = LocationCSV.parse_string(csv)

        {id_to_city, city_to_id} =
          Enum.reduce(parsed_csv, {%{}, %{}}, fn [id, name, country_code],
                                                 {id_to_city, city_to_id} ->
            id = String.to_integer(id)
            id_to_city = Map.put(id_to_city, id, {name, country_code})
            city_to_id = Map.put_new(city_to_id, {name, country_code}, id)
            {id_to_city, city_to_id}
          end)

        :persistent_term.put(:location_id_to_city, id_to_city)
        :persistent_term.put(:location_city_to_id, city_to_id)
      end)

    Task.await(task, :timer.seconds(30))
  end

  def read_map do
    Task.await(
      Task.async(fn ->
        id_to_city = :erlang.binary_to_term(File.read!("id_to_city.bin"))
        :persistent_term.put(:location_id_to_city, id_to_city)
      end)
    )

    Enum.each(Process.list(), &:erlang.garbage_collect/1)
  end

  def get_city_map(id) when is_integer(id) do
    id_to_city = :persistent_term.get(:location_id_to_city)
    Map.get(id_to_city, id)
  end
end
