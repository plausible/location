defmodule Mix.Tasks.UpdateIsoData do
  use Mix.Task

  @countries_src "https://salsa.debian.org/iso-codes-team/iso-codes/-/raw/main/data/iso_3166-1.json"
  @subdivisions_src "https://salsa.debian.org/iso-codes-team/iso-codes/-/raw/main/data/iso_3166-2.json"
  @countries_dest Application.app_dir(:location, "/priv/iso_3166-1.json")
  @subdivisions_dest Application.app_dir(:location, "/priv/iso_3166-2.json")

  def run(_) do
    HTTPoison.start()

    %HTTPoison.Response{status_code: 200, body: countries} = HTTPoison.get!(@countries_src)
    File.write!(@countries_dest, countries)

    %HTTPoison.Response{status_code: 200, body: subdivisions} = HTTPoison.get!(@subdivisions_src)
    %{"3166-2" => subdivisions} = Jason.decode!(subdivisions)
    subdivisions = Enum.map(fn subdivision -> Map.delete(subdivision, "parent") end)
    subdivisions = Jason.encode_to_iodata!(%{"3166-2" => subdivisions})
    File.write!(@subdivisions_dest, subdivisions)
  end
end
