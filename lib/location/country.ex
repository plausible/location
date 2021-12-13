defmodule Location.Country do
  @ets_table :countries

  defstruct [:alpha_2, :alpha_3, :name, :flag]

  def load(heir) do
    ets = :ets.new(@ets_table, [:named_table, {:heir, heir, []}])

    File.read!(source_file())
    |> Jason.decode!()
    |> Map.fetch!("3166-1")
    |> Enum.each(fn entry ->
      :ets.insert(ets, {entry["alpha_2"], to_struct(entry)})
    end)

    File.read!(override_source_file())
    |> Jason.decode!()
    |> Enum.each(fn entry ->
      :ets.insert(ets, {entry["alpha_2"], to_struct(entry)})
    end)
  end

  def all() do
    :ets.tab2list(@ets_table)
    |> Enum.map(fn {_, val} -> val end)
  end

  def search_country(search_phrase) do
    search_phrase = String.downcase(search_phrase)

    :ets.foldl(fn
      {_code, entry}, acc ->
        if String.contains?(String.downcase(entry.name), search_phrase) do
          [entry | acc]
        else
          acc
        end
    end, [], @ets_table)
  end

  def get_country(code) do
    case :ets.lookup(@ets_table, code) do
      [{_, entry}] -> entry
      _ -> nil
    end
  end

  defp to_struct(entry) do
    %__MODULE__{
      name: entry["common_name"] || entry["name"],
      flag: entry["flag"],
      alpha_2: entry["alpha_2"],
      alpha_3: entry["alpha_3"],
    }
  end

  defp source_file() do
    Application.app_dir(:location, "priv/iso_3166-1.json")
  end

  defp override_source_file() do
    Application.app_dir(:location, "priv/override/iso_3166-1.json")
  end
end
