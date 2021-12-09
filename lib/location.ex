defmodule Location do
  require Logger
  defdelegate get_country(alpha_2), to: Location.Country
  defdelegate get_subdivision(code), to: Location.Subdivision
  defdelegate get_city(code), to: Location.City

  def load_all do
    me = self()

    Logger.debug("Loading location databases...")

    [
      Task.async(fn -> Location.Country.load(me) end),
      Task.async(fn -> Location.Subdivision.load(me) end),
      Task.async(fn -> Location.City.load(me) end)
    ] |> Enum.map(fn task -> Task.await(task, 15_000) end)

    Logger.debug("Location databases loaded")
  end
end
