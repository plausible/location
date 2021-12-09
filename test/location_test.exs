defmodule LocationTest do
  use ExUnit.Case
  doctest Location

  setup_all do
    Location.load_all()

    :ok
  end

  test "can look up a country" do
    country = Location.get_country("EE")

    assert country.name == "Estonia"
  end

  test "can look up a subdivision" do
    subdiv = Location.get_subdivision("EE-79")

    assert subdiv.name == "Tartumaa"
    assert subdiv.country_code == "EE"
    assert subdiv.type == "County"
  end

  test "can look up a city" do
    city = Location.get_city(588335)

    assert city.name == "Tartu"
    assert city.country_code == "EE"
  end
end
