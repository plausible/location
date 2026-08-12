defmodule Mix.Tasks.Location.UpdateUspsData do
  use Mix.Task
  @shortdoc "Updates the postal code data from source"

  @destination_filename Application.compile_env(
                          :location,
                          :postal_codes_source_file,
                          "priv/postal_codes.csv"
                        )

  @doc """
  The data source clocks in at 16mb. Expect this to take a while.
  The option --source will download and parse different datasets ie. AZ (https://download.geonames.org/export/zip/AZ.zip) in order to keep the set small
  """

  def run(args) do
    {options, _, _} =
      OptionParser.parse(args,
        strict: [append: :boolean]
      )

    options = Keyword.merge([help: false, list: false, append: false], options)

    main(Keyword.get(options, :append))
  end

  @doc """
  Fetch and Prepare a Postal Code Export

  """
  def main(append \\ false) do
    ## fetch the file
    {200, _, doc} = Location.HTTP.get!("https://postalpro.usps.com/ZIP_Locale_Detail")
    {:ok, html} = Floki.parse_document(doc)

    [
      {"a",
       [
         {"href", href},
         {"class", _},
         {"title", "Download ZIP Codes by Area and District codes"}
       ], ["Download"]}
    ] = Floki.find(html, ".mt-1")

        src = "https://postalpro.usps.com#{href}"
        System.cmd("wget", [src, "-O", "/tmp/usps_zip_codes.xls"])
        process_file("/tmp/usps_zip_codes.xls", append)
  end

  defp process_file(filename, append) do
    # BINARY
    tab = :binary.compile_pattern("\t")

    result =
      filename
      |> File.stream!(read_ahead: 100_000)
      |> Flow.from_enumerable()
      |> Flow.map(&(String.trim(&1) |> String.split(tab)))
      |> Flow.partition()
      |> Enum.into([])

    IO.puts("Writing result to #{@destination_filename}")

    Location.Scraper.write_date_to_version()

    file = File.open!(@destination_filename, [:write, :utf8])
    result |> CSV.encode() |> Enum.each(&IO.write(file, &1))
  end
end
