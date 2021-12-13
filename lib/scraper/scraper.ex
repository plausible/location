defmodule Location.Scraper do
  @base_url "https://en.wikipedia.org"
  @subdivision_base_url @base_url <> "/wiki/ISO_3166-2:"
  @translations_dest Application.app_dir(:location, "/priv/iso_3166-2.en-translations.json")
  @countries_to_skip ["EE"] # For estonia the local names are better than English ones

  def scrape() do
    countries = Location.Country.all()

    res = Enum.map(countries, &scrape_country/1)
    |> Enum.filter(&(not is_nil(&1)))
    |> List.flatten
    |> Enum.into(%{})
    |> Jason.encode!

    File.write!(@translations_dest, res)
  end

  defp scrape_country(%Location.Country{alpha_2: code}) when code in @countries_to_skip, do: nil
  defp scrape_country(country) do
    IO.puts("Fetching data for " <> country.name)

    url = @subdivision_base_url <> country.alpha_2
    response = HTTPoison.get!(url)
    {:ok, document} = Floki.parse_document(response.body)

    rows = Floki.find(document, "table.wikitable.sortable")
    |> List.first
    |> Floki.find("tbody tr")

    english_name_column = case List.first(rows) do
      {"tr", _attrs, cells} ->
        Enum.find_index(cells, fn cell -> String.starts_with?(String.downcase(cell_text(cell)), "subdivision name (en)") end)
      _ -> nil
    end

    if english_name_column do
      Enum.drop(rows, 1)
      |> Enum.map(fn row -> scrape_row(row, english_name_column) end)
    end
  end

  defp scrape_row({"tr", _attrs, children}, name_column_index) do
    code = children
    |> Enum.at(0)
    |> cell_text

    name = children
    |> Enum.at(name_column_index)
    |> cell_text

    {code, name}
  end

  defp cell_text(text) do
    Floki.text(text)
    |> String.trim()
    |> String.trim("[a]")
    |> String.replace(~r/\[note \d\]$/, "") # Sometimes the entry contains something like "Region name[note 3]"
  end
end
