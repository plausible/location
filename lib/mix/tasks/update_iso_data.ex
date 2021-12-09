defmodule Mix.Tasks.UpdateIsoData do
  use Mix.Task

  @countries_src "https://salsa.debian.org/iso-codes-team/iso-codes/-/raw/main/data/iso_3166-1.json"
  @subdivisions_src "https://salsa.debian.org/iso-codes-team/iso-codes/-/raw/main/data/iso_3166-2.json"
  @countries_dest Application.app_dir(:location, "/priv/iso_3166-1.json")
  @subdivisions_dest Application.app_dir(:location, "/priv/iso_3166-2.json")

  def run(_) do
    HTTPoison.start()

    response = HTTPoison.get!(@countries_src)
    File.write!(@countries_dest, response.body)

    response = HTTPoison.get!(@subdivisions_src)
    File.write!(@subdivisions_dest, response.body)
  end
end
