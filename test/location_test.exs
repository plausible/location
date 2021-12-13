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
      [match] = Location.search_country("est")

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
      city = Location.get_city(588335)

      assert city.name == "Tartu"
      assert city.country_code == "EE"
    end

    test "can search a city by name, case insensitive" do
      [match] = Location.search_city("otepä")

      assert match.id == 589782
      assert match.name == "Otepää"
    end
  end
end
