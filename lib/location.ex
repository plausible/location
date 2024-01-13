NimbleCSV.define(LocationCSV, separator: "\t", escape: "\~")

defmodule Location do
  require Logger
  defdelegate get_country(alpha_2), to: Location.Country
  defdelegate search_country(alpha_2), to: Location.Country
  defdelegate get_subdivision(code), to: Location.Subdivision
  defdelegate search_subdivision(code), to: Location.Subdivision
  defdelegate get_city(code), to: Location.City
  defdelegate get_city(city_name, country_code), to: Location.City
  defdelegate get_postal_codes(country_code, state_code, city_name), to: Location.PostalCode

  def load_all() do
    Logger.debug("Loading location databases...")

    :ok = load(Location.Country)
    :ok = load(Location.Subdivision)
    :ok = load(Location.City)
    :ok = load(Location.PostalCode)
  end

  defp load(module) do
    {t, _result} =
      :timer.tc(fn ->
        module.load()
      end)

    time = t / 1_000_000

    Logger.debug("Loading location database #{inspect(module)} took: #{time}s")
    :ok
  end
end
