defmodule Location.Scraper do
  @base_url "https://en.wikipedia.org/wiki/ISO_3166-2:"
  @translations_dest Application.app_dir(:location, "/priv/iso_3166-2.en-translations.json")
  @countries_to_skip [
    # For Estonia the local names are better than English ones
    "EE",
    # Source data from salsa-debian already has english translations where applicable
    "JP",
    "MW",
    "FJ",
    "GH",
    "UG",
    "BB"
  ]

  def scrape() do
    countries = Location.Country.all()

    res =
      Enum.map(countries, &scrape_country/1)
      |> Enum.filter(&(not is_nil(&1)))
      |> List.flatten()
      |> Jason.OrderedObject.new()
      |> Jason.encode_to_iodata!(pretty: true)

    File.write!(@translations_dest, res)
  end

  defp scrape_country(%Location.Country{alpha_2: code}) when code in @countries_to_skip, do: nil

  defp scrape_country(country) do
    url = @base_url <> country.alpha_2
    {200, _headers, body} = Location.HTTP.get!(url)
    {:ok, document} = Floki.parse_document(body)

    rows =
      document
      |> Floki.find("table.wikitable.sortable")
      |> Enum.flat_map(fn table ->
        rows = Floki.find(table, "tbody tr")

        english_name_column =
          case List.first(rows) do
            {"tr", _attrs, cells} ->
              Enum.find_index(cells, fn cell ->
                text = String.downcase(cell_text(cell))
                # https://github.com/plausible/analytics/issues/3260
                if country.alpha_2 == "SE" do
                  String.starts_with?(text, "subdivision name (sv)")
                else
                  String.starts_with?(text, "subdivision name (en)")
                end
              end)

            _ ->
              nil
          end

        if english_name_column do
          IO.puts(IO.ANSI.green() <> "Scraping " <> country.name <> IO.ANSI.reset())

          Enum.drop(rows, 1)
          |> Enum.map(fn row -> scrape_row(row, english_name_column) end)
          |> Enum.uniq_by(fn {code, _name} -> code end)
          |> Enum.sort_by(fn {code, _name} -> code end)
        else
          IO.puts(IO.ANSI.red() <> "Skipping " <> country.name <> IO.ANSI.reset())
          []
        end
      end)
  end

  defp scrape_row({"tr", _attrs, children}, name_column_index) do
    code =
      children
      |> Enum.at(0)
      |> cell_text

    name =
      children
      |> Enum.at(name_column_index)
      |> cell_text

    {code, name}
  end

  defp cell_text(text) do
    Floki.text(text)
    |> String.trim()
    |> String.trim("[a]")
    # Sometimes the entry contains something like "Region name[note 3]"
    |> String.replace(~r/\[note \d\]$/, "")
  end
end
