defmodule Mix.Tasks.UpdatePostalCodeData do
  use Mix.Task

  @allcountries_src "https://download.geonames.org/export/zip/allCountries.zip"
  @allcountries_dest Application.app_dir(:location, "/priv/postal_codes.csv")

  @doc """
  The data source allCountries.zip clocks in at 16mb. Expect this to take a while.
  """
  def run(_) do
    System.cmd("wget", [@allcountries_src, "-O", "/tmp/allCountries.zip"])
    System.cmd("unzip", ["/tmp/allCountries.zip", "-d", "/tmp"])

    process_file("/tmp/allCountries.txt")
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

    IO.puts("Writing result to #{@allcountries_dest}")

    File.write!(@allcountries_dest, Enum.join(result, "\n"))
  end
end
