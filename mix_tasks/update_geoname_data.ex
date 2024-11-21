defmodule Mix.Tasks.UpdateGeonameData do
  use Mix.Task

  # @allcountries_src "https://download.geonames.org/export/dump/allCountries.zip"
  @allcountries_dest Application.app_dir(:location, "/priv/geonames.csv")

  @doc """
  The data source allCountries.txt clocks in at 1.5GB. Expect this to take a while.
  """
  def run(_) do
    tmp_txt = Path.join(System.tmp_dir!(), "allCountries.txt")

    unless File.exists?(tmp_txt) do
      System.cmd("wget", [@allcountries_src, "-O", "/tmp/allCountries.zip"])
      System.cmd("unzip", ["/tmp/allCountries.zip", "-d", "/tmp"])
    end

    process_geonames_file(tmp_txt)
  end

  defp process_geonames_file(filename) do
    # BINARY
    tab = :binary.compile_pattern("\t")

    result =
      filename
      |> File.stream!(read_ahead: 100_000)
      |> Flow.from_enumerable()
      |> Flow.map(&String.split(&1, tab))
      |> Flow.partition()
      |> Flow.reduce(fn -> [] end, &reduce_chunk/2)
      |> Enum.into([])

    IO.puts("Writing result to #{@allcountries_dest}")

    File.write!(@allcountries_dest, Enum.join(result, "\n"))

    Location.Scraper.write_date_to_version()
  end

  defp reduce_chunk(row, result) do
    case row do
      # feature classes defined here: http://download.geonames.org/export/dump/
      [geoname_id, name, _, _, _, _, feature_class, _, country_code | _rest]
      when feature_class in ["P", "A"] ->
        row = geoname_id <> "\t" <> name <> "\t" <> country_code
        [row | result]

      _ ->
        result
    end
  end
end
