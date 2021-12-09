defmodule Location.Subdivision do
  @ets_table :iso_3166_2

  defstruct [:code, :name, :type, :country_code]

  def load(heir) do
    ets = :ets.new(@ets_table, [:named_table, {:heir, heir, []}])

    translations = File.read!(translations_file()) |> Jason.decode!()

    File.read!(source_file())
    |> Jason.decode!()
    |> Map.fetch!("3166-2")
    |> Enum.each(fn entry ->
      entry = translate_entry(translations, entry)
      :ets.insert(ets, {entry["code"], to_struct(entry)})
    end)

    File.read!(override_source_file())
    |> Jason.decode!()
    |> Enum.each(fn entry ->
      :ets.insert(ets, {entry["code"], to_struct(entry)})
    end)
  end

  def get_subdivision(code) do
    case :ets.lookup(@ets_table, code) do
      [{_, entry}] -> entry
      _ -> nil
    end
  end

  defp to_struct(entry) do
    country_code = entry["code"] |> String.split("-") |> List.first

    %__MODULE__{
      code: entry["code"],
      name: entry["name"],
      type: entry["type"],
      country_code: country_code
    }
  end

  defp translate_entry(translations, entry) do
    case Map.get(translations, entry["code"]) do
      nil -> entry
      translation ->
        Map.put(entry, "name", translation)
    end
  end

  defp source_file() do
    Application.app_dir(:location, "priv/iso_3166-2.json")
  end

  defp translations_file() do
    Application.app_dir(:location, "priv/override/iso_3166-2.en-translations.json")
  end

  defp override_source_file() do
    Application.app_dir(:location, "priv/override/iso_3166-2.json")
  end
end
