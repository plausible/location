defmodule Mix.Tasks.UpdatePostalCodeData do
  use Mix.Task

  @destination_filename Location.PostalCode.source_file()

  @doc """
  The data source clocks in at 16mb. Expect this to take a while.
  The option --source will download and parse different datasets ie. AZ (https://download.geonames.org/export/zip/AZ.zip) in order to keep the set small
  """

  def run(args) do
    {options, _, _} =
      OptionParser.parse(["--source", "allCountries"], strict: [source: :string])

    Keyword.get(options, :source)
    |> main()
  end

  @doc """
  Fetch and Prepare a Postal Code Export

  """
  def main(name) do
    src = "https://download.geonames.org/export/zip/#{name}.zip"
    System.cmd("wget", [src, "-O", "/tmp/#{name}.zip"])
    System.cmd("unzip", ["/tmp/#{name}.zip", "-d", "/tmp"])

    process_file("/tmp/#{name}.txt")
  end

  defp process_file(filename) do
    # BINARY
    tab = :binary.compile_pattern("\t")

    result =
      filename
      |> File.stream!(read_ahead: 100_000)
      |> Flow.from_enumerable()
      |> Flow.map(&String.split(&1, tab))
      |> Flow.partition()
      |> Enum.into([])

    IO.puts("Writing result to #{@destination_filename}")

    File.write!(@destination_filename, Enum.join(result, "\n"))
  end
end
