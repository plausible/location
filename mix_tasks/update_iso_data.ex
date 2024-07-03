defmodule Mix.Tasks.UpdateIsoData do
  require Logger
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
      Enum.map(new_subdivisions, fn %{"code" => code} = subdivision ->
        subdivision
        |> Map.delete("parent")
        |> Map.update!(
          "name",
          fn debian_name ->
            short_code = String.replace(code, "-", "")
            cldr_name(short_code) || manual_en_name(code, debian_name)
          end
        )
      end)

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

  defp cldr_name(short_code) do
    with {:ok, en_name} <- Location.Cldr.Territory.from_subdivision_code(short_code) do
      en_name
    else
      _ -> nil
    end
  end

  # TODO: add these to CLDR https://github.com/pedberg-icu/cldr/blob/main/common/subdivisions/en.xml
  # or https://salsa.debian.org/iso-codes-team/iso-codes/-/blob/main/iso_3166-2/en.po
  manual_code_to_en_name = %{
    # https://en.wikipedia.org/wiki/ISO_3166-2:ID
    "ID-PD" => "Southwest Papua",
    "ID-PE" => "Highland Papua",
    "ID-PS" => "South Papua",
    "ID-PT" => "Central Papua",
    # https://en.wikipedia.org/wiki/ISO_3166-2:IS
    "IS-HUG" => "Huna Settlement",
    "IS-SKR" => "Skagafjordur",
    # https://en.wikipedia.org/wiki/ISO_3166-2:KP
    "KP-15" => "Kaesong",
    # https://en.wikipedia.org/wiki/ISO_3166-2:KZ
    "KZ-10" => "Abai",
    "KZ-11" => "Akmola",
    "KZ-15" => "Aktobe",
    "KZ-19" => "Almaty",
    "KZ-23" => "Atyrau",
    "KZ-27" => "West Kazakhstan",
    "KZ-31" => "Jambyl",
    "KZ-33" => "Jetisu",
    "KZ-35" => "Karaganda",
    "KZ-39" => "Kostanay",
    "KZ-43" => "Kyzylorda",
    "KZ-47" => "Mangystau",
    "KZ-55" => "Pavlodar",
    "KZ-59" => "North Kazakhstan",
    "KZ-61" => "Turkistan",
    "KZ-62" => "Ulytau",
    "KZ-63" => "East Kazakhstan",
    "KZ-71" => "Astana",
    "KZ-75" => "Almaty City",
    "KZ-79" => "Shymkent"
  }

  for {code, en_name} <- manual_code_to_en_name do
    defp manual_en_name(unquote(code), debian_name) do
      warn_if_debian_got_english(unquote(code), unquote(en_name), debian_name)
    end
  end

  defp manual_en_name(code, debian_name) do
    Logger.warning(
      "no translation override for #{code}, assuming Debian anme is English, please check: #{debian_name}"
    )

    debian_name
  end

  defp warn_if_debian_got_english(code, manual_name, debian_name) do
    if manual_name == debian_name do
      Logger.warning(
        "Debian seems to have localized #{code}, the manual translation can be removed"
      )
    end

    manual_name
  end
end
