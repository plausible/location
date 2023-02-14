defmodule Location do
  require Logger
  defdelegate get_country(alpha_2), to: Location.Country
  defdelegate search_country(alpha_2), to: Location.Country
  defdelegate get_subdivision(code), to: Location.Subdivision
  defdelegate search_subdivision(code), to: Location.Subdivision
  defdelegate get_city(code), to: Location.City
  defdelegate get_city(city_name, country_code), to: Location.City

  def load_all(timeout \\ 30_000) do
    me = self()

    Logger.debug("Loading location databases...")

    [
      Task.async(fn -> Location.Country.load(me) end),
      Task.async(fn -> Location.Subdivision.load(me) end),
      Task.async(fn -> Location.City.load(me) end)
    ]
    |> Task.await_many(timeout)

    Logger.debug("Location databases loaded")
  end
end
