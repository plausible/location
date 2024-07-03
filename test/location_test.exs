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

    test "can lookup former subdivisions" do
      # changed to FR-75C in 2021-11-25: https://en.wikipedia.org/wiki/ISO_3166-2:FR#Changes
      assert Location.get_subdivision("FR-75").name == "Paris"

      # FR-GF and some other codes were removed in 2021-11-25: https://en.wikipedia.org/wiki/ISO_3166-2:FR#Changes
      assert Location.get_subdivision("FR-GF").name == "Guyane (française)"

      # GT-AV and some other codes were changed in 2021-11-25: https://en.wikipedia.org/wiki/ISO_3166-2:GT#Changes
      assert Location.get_subdivision("GT-AV").name == "Alta Verapaz"

      # IN-CT and some other codes were changed in 2023-11-23: https://en.wikipedia.org/wiki/ISO_3166-2:IN#Changes
      assert Location.get_subdivision("IN-CT").name == "Chhattīsgarh"

      # IS-BFJ and some other codes were removed in 2021-11-25: https://en.wikipedia.org/wiki/ISO_3166-2:IS#Changes
      assert Location.get_subdivision("IS-BFJ").name == "Borgarfjarðarhreppur"

      # IS-AKH and some other codes were removed in 2022-11-29: https://en.wikipedia.org/wiki/ISO_3166-2:IS#Changes
      assert Location.get_subdivision("IS-AKH").name == "Akrahreppur"

      # KZ-ALA and some other codes were changed in 2022-11-29: https://en.wikipedia.org/wiki/ISO_3166-2:KZ#Changes
      assert Location.get_subdivision("KZ-ALA").name == "Almaty"

      # LV-001 and some other codes were removed in 2021-11-25: https://en.wikipedia.org/wiki/ISO_3166-2:LV#Changes
      assert Location.get_subdivision("LV-001").name == "Aglonas novads"

      # NP-1 and some other codes were removed in 2022-11-29: https://en.wikipedia.org/wiki/ISO_3166-2:NP#Changes
      assert Location.get_subdivision("NP-1").name == "Central"

      # PH-MAG was split in two in 2023-11-23: https://en.wikipedia.org/wiki/ISO_3166-2:PH#Changes
      assert Location.get_subdivision("PH-MAG").name == "Maguindanao"
    end

    test "is translated to English" do
      # JP
      assert Location.get_subdivision("JP-13").name == "Tokyo"
      assert Location.get_subdivision("JP-21").name == "Gifu"

      # MW
      assert Location.get_subdivision("MW-C").name == "Central Region"
      assert Location.get_subdivision("MW-BA").name == "Balaka"

      # FJ
      assert Location.get_subdivision("FJ-03").name == "Cakaudrove"
      assert Location.get_subdivision("FJ-08").name == "Nadroga and Navosa"
      assert Location.get_subdivision("FJ-C").name == "Central"

      # GH
      assert Location.get_subdivision("GH-AA").name == "Greater Accra"
      assert Location.get_subdivision("GH-CP").name == "Central"
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
