defmodule Location.PostalCode do
  @ets_table_by_id __MODULE__
  @ets_table_by_lookup Module.concat(__MODULE__, ByLookup)

  defstruct [
    :postal_code,
    :country_code,
    :state_code,
    :city_name,
    :latitude,
    :longitude
  ]

  def load() do
    @ets_table_by_lookup =
      :ets.new(@ets_table_by_lookup, [
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
        |> Stream.each(fn [
                            country_code,
                            postal_code,
                            city_name,
                            _state_name,
                            state_code,
                            _municipality,
                            _municipality_code,
                            _admin_name3,
                            _admin_code3,
                            latitude,
                            longitude,
                            _accuracy
                          ] ->
          country_code = String.trim(country_code)

          true =
            :ets.insert(
              @ets_table_by_lookup,
              {{country_code, state_code, city_name}, {postal_code, latitude, longitude}}
            )

          true =
            :ets.insert(
              @ets_table_by_id,
              {postal_code, {country_code, state_code, city_name, latitude, longitude}}
            )
        end)
        |> Stream.run()
      end,
      timeout: :infinity
    )
    |> Stream.run()
  end

  @doc """
  Finds postal_code information by postal code.
  """
  @spec get_postal_code(string()) :: %__MODULE__{} | nil
  def get_postal_code(code) do
    case :ets.lookup(@ets_table_by_id, code) do
      [{postal_code, {country_code, state_code, city_name, latitude, longitude}}] ->
        to_struct(postal_code, country_code, state_code, city_name, latitude, longitude)

      _ ->
        nil
    end
  end

  @doc """
  Finds postal codes by city code, state code and country code.

  This function returns all postal code founds when the country has multiple
  cities with the same name.
  """
  @spec get_postal_codes(string(), string(), string()) :: %__MODULE__{} | nil
  def get_postal_codes(country_code, state_code, city_name) do
    case :ets.lookup(@ets_table_by_lookup, {country_code, state_code, city_name}) do
      data when is_list(data) ->
        Enum.map(data, fn x ->
          {{country_code, state_code, city_name}, {postal_code, latitude, longitude}} = x
          to_struct(postal_code, country_code, state_code, city_name, latitude, longitude)
        end)

      _ ->
        nil
    end
  end

  def source_file() do
    default = Application.app_dir(:location, "/priv/postal_codes.csv")
    Application.get_env(:location, :postal_codes_source_file, default)
  end

  defp to_struct(postal_code, country_code, state_code, city_name, latitude, longitude) do
    %__MODULE__{
      postal_code: postal_code,
      country_code: country_code,
      state_code: state_code,
      city_name: city_name,
      latitude: latitude,
      longitude: longitude
    }
  end
end
