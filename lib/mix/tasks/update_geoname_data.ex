defmodule Mix.Tasks.UpdateGeonameData do
  use Mix.Task

  @destination_filename Location.PostalCode.source_file()

  @doc """
  The data source clocks in at 1.5GB. Expect this to take a while.
  """

  def run(args) do
    {options, _, _} =
      OptionParser.parse(["--source", "allCountries"], strict: [source: :string])

    Keyword.get(options, :source)
    |> main()
  end

  def main(name) do
    #    src = "https://download.geonames.org/export/dump/#{name}.zip"
    #    System.cmd("wget", [src, "-O", "/tmp/#{name}.zip"])
    #    System.cmd("unzip", ["/tmp/#{name}.zip", "-d", "/tmp"])

    process_geonames_file("/tmp/#{name}.txt")
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

    IO.puts("Writing result to #{@destination_filename}")

    File.write!(@destination_filename, Enum.join(result, "\n"))
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
