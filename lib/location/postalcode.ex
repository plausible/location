defmodule Location.PostalCode do
  @ets_table_by_lookup Module.concat(__MODULE__, ByLookup)

  defstruct [
    :country_code,
    :state_code,
    :city_name,
    :postal_code
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
                            _latitude,
                            _longitude,
                            _accuracy
                          ] ->
          country_code = String.trim(country_code)

          true =
            :ets.insert(
              @ets_table_by_lookup,
              {{country_code, state_code, city_name}, postal_code}
            )
        end)
        |> Stream.run()
      end,
      timeout: :infinity
    )
    |> Stream.run()
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
          {{country_code, state_code, city_name}, postal_code} = x
          to_struct(country_code, state_code, city_name, postal_code)
        end)

      _ ->
        nil
    end
  end

  defp source_file() do
    Application.app_dir(:location, "priv/postal_codes.csv")
  end

  defp to_struct(country_code, state_code, city_name, postal_code) do
    %__MODULE__{
      country_code: country_code,
      state_code: state_code,
      city_name: city_name,
      postal_code: postal_code
    }
  end
end
