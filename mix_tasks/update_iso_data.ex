defmodule Mix.Tasks.UpdateIsoData do
  use Mix.Task

  @countries_src "https://salsa.debian.org/iso-codes-team/iso-codes/-/raw/main/data/iso_3166-1.json"
  @subdivisions_src "https://salsa.debian.org/iso-codes-team/iso-codes/-/raw/main/data/iso_3166-2.json"
  @countries_dest Application.app_dir(:location, "/priv/iso_3166-1.json")
  @subdivisions_dest Application.app_dir(:location, "/priv/iso_3166-2.json")

  def run(_) do
    {200, _headers, countries} = Location.HTTP.get!(@countries_src)
    File.write!(@countries_dest, countries)

    {200, _headers, new_subdivisions} = Location.HTTP.get!(@subdivisions_src)
    %{"3166-2" => new_subdivisions} = Jason.decode!(new_subdivisions)

    new_subdivisions =
      Enum.map(new_subdivisions, fn subdivision -> Map.delete(subdivision, "parent") end)

    new_subdivisions_codes = MapSet.new(new_subdivisions, fn %{"code" => code} -> code end)

    # ensures no codes are deleted
    # if a code no longer exists in new subdivisions, we put it in restore folder
    restored_subdivisions_path = Application.app_dir(:location, "/priv/restore/iso_3166-2.json")

    new_restored_subdivisions =
      if File.exists?(@subdivisions_dest) do
        File.read!(@subdivisions_dest)
        |> Jason.decode!()
        |> Map.fetch!("3166-2")
        |> Enum.reject(fn %{"code" => code} -> MapSet.member?(new_subdivisions_codes, code) end)
      end

    prev_restored_subdivisions =
      if File.exists?(restored_subdivisions_path) do
        Jason.decode!(File.read!(restored_subdivisions_path))
      end

    restored_subdivisions =
      (new_restored_subdivisions || []) ++ (prev_restored_subdivisions || [])

    restored_subdivisions =
      restored_subdivisions
      |> Enum.uniq_by(fn %{"code" => code} -> code end)
      |> Enum.sort_by(fn %{"code" => code} -> code end)

    File.write!(
      restored_subdivisions_path,
      Jason.encode_to_iodata!(restored_subdivisions, pretty: true)
    )

    new_subdivisions = Jason.encode_to_iodata!(%{"3166-2" => new_subdivisions}, pretty: true)
    File.write!(@subdivisions_dest, new_subdivisions)
  end
end
