defmodule Mix.Tasks.UpdateGeonameData do
  use Mix.Task

  default = Application.app_dir(:location, "/priv/postal_codes.csv")
  @destination_filename Application.get_env(:location, :postal_codes_source_file, default)

  @doc """
  The data source clocks in at 1.5GB. Expect this to take a while.
  """

  def run(args) do
    {options, _, _} =
      OptionParser.parse(["--source", "allCountries", "--list", "--append", "--help"],
        strict: [source: :string, list: :boolean, append: :boolean, help: :boolean]
      )

    case(Keyword.get(options, :help) || Keyword.get(options, :list)) do
      false ->
        Keyword.get(options, :source)
        |> main(Keyword.get(options, :append))

      true ->
        if(Keyword.get(options, :help)) do
          IO.puts(
            "The following options are available, --source 'Choose an option from --list', --list 'List of available countries by code', --append 'Append to the downloaded file (if you want multiple countries but not all)'"
          )
        end

        if(Keyword.get(options, :list)) do
          sources = Location.Scraper.scrape_postal_files()
          IO.puts("The following Postal Code Sources are Available #{sources}")
        end
    end
  end

  def main(name, append \\ false) do
    #    src = "https://download.geonames.org/export/dump/#{name}.zip"
    #    System.cmd("wget", [src, "-O", "/tmp/#{name}.zip"])
    #    System.cmd("unzip", ["/tmp/#{name}.zip", "-d", "/tmp"])

    process_geonames_file("/tmp/#{name}.txt", append)
  end

  defp process_geonames_file(filename, append \\ false) do
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

    IO.puts("Writing result to #{@destination_filename}")

    case append do
      false -> File.write!(@destination_filename, Enum.join(result, "\n"))
      true -> File.write!(@destination_filename, Enum.join(result, "\n"), :append)
    end
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
