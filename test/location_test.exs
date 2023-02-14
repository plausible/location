defmodule LocationTest do
  use ExUnit.Case
  doctest Location

  setup_all do
    Location.load_all()

    :ok
  end

  describe "country" do
    test "can look up a country by ISO code" do
      country = Location.get_country("EE")

      assert country.name == "Estonia"
    end

    test "can search a country by name, case insensitive" do
      [match] = Location.search_country("eston")

      assert match.alpha_2 == "EE"
      assert match.name == "Estonia"
    end
  end

  describe "subdivision" do
    test "can look up a subdivision by ISO code" do
      subdiv = Location.get_subdivision("EE-79")

      assert subdiv.name == "Tartumaa"
      assert subdiv.country_code == "EE"
      assert subdiv.type == "County"
    end

    test "can search a subdivision by name, case insensitive" do
      [match] = Location.search_subdivision("tartum")

      assert match.code == "EE-79"
      assert match.name == "Tartumaa"
    end
  end

  describe "city" do
    test "can look up a city" do
      city = Location.get_city(588_335)

      assert city.name == "Tartu"
      assert city.country_code == "EE"
    end

    test "can reverse lookup a city by name and country" do
      city = Location.City.get_city("Curitiba", "BR")

      assert city.country_code == "BR"
      assert city.name == "Curitiba"
      assert city.id == 3_464_975
    end

    test "returns nil when city name doesn't match country" do
      city = Location.get_city("Curitiba", "EE")
      assert is_nil(city)
    end

    test "returns first match when country has multiple cities with the same name" do
      city = Location.get_city("Springfield", "AU")

      assert city.country_code == "AU"
      assert city.id == 8_349_432
      assert city.name == "Springfield"
    end
  end
end
