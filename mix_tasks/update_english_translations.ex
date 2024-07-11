defmodule Mix.Tasks.UpdateEnglishTranslations do
  use Mix.Task

  @cldr_url "https://raw.githubusercontent.com/unicode-org/cldr/main/common/subdivisions/en.xml"
  @translations_dest Application.app_dir(:location, "/priv/iso_3166-2.en-translations.json")

  def run(_) do
    {200, _headers, cldr_xml} = Location.HTTP.get!(@cldr_url)
    cldr_translations = parse_cldr_xml(cldr_xml)

    %{"3166-2" => debian} = read_json("priv/iso_3166-2.json")
    restored = read_json("priv/restore/iso_3166-2.json")
    overrides = read_json("priv/override/iso_3166-2.json")

    subdivisions =
      (debian ++ restored ++ overrides)
      |> Enum.uniq_by(fn %{"code" => code} -> code end)
      |> Enum.sort_by(fn %{"code" => code} -> code end)

    translations =
      subdivisions
      |> Enum.map(fn %{"code" => code, "name" => debian_name} ->
        short_code = code |> String.replace("-", "") |> String.downcase()
        cldr_name = Map.get(cldr_translations, short_code)

        cond do
          skip?(code) ->
            colored_put(
              IO.ANSI.yellow(),
              "#{code}: skipping, Debian name will be used, please check: #{debian_name}"
            )

            nil

          manual_name = manual_en_name(code) ->
            cond do
              manual_name == debian_name ->
                colored_put(
                  IO.ANSI.yellow(),
                  "#{code}: Debian localized it, the manual translation can be removed"
                )

                nil

              manual_name == cldr_name ->
                colored_put(
                  IO.ANSI.yellow(),
                  "#{code}: CLDR fixed it, the manual translation can be removed"
                )

                nil

              true ->
                colored_put(IO.ANSI.yellow(), "#{code}: manual translation used: #{manual_name}")
                {code, manual_name}
            end

          cldr_name == debian_name ->
            colored_put(
              IO.ANSI.blue(),
              "#{code}: Debian and CLDR names are the same, assuming they are both English, please check: #{debian_name}"
            )

            nil

          cldr_name ->
            colored_put(
              IO.ANSI.green(),
              "#{code}: CLDR translation found, please check: #{debian_name} -> #{cldr_name}"
            )

            {code, cldr_name}

          true ->
            colored_put(
              IO.ANSI.yellow(),
              "#{code}: no translation found, assuming Debian name is English, please check: #{debian_name}"
            )

            nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    json =
      translations
      |> Jason.OrderedObject.new()
      |> Jason.encode_to_iodata!(pretty: true)

    File.write!(@translations_dest, json)
  end

  manual_code_to_en_name = %{
    # https://unicode-org.atlassian.net/browse/CLDR-17777
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
    "KZ-75" => "Almaty City",
    # https://en.wikipedia.org/wiki/ISO_3166-2:FI
    "FI-01" => "Åland",
    "FI-06" => "Kanta-Häme",
    "FI-16" => "Päijät-Häme",
    # https://en.wikipedia.org/wiki/ISO_3166-2:FR
    "FR-BL" => "Saint Barts",
    "FR-NC" => "New Caledonia",
    "FR-PF" => "French Polynesia",
    "FR-PM" => "Saint Peter and Miquelon",
    "FR-TF" => "French Southern Territories",
    "FR-WF" => "Wallis and Futuna",
    # the following are "fixes" for CLDR, taken from Wikipedia
    # https://en.wikipedia.org/wiki/ISO_3166-2:RU
    "RU-YEV" => "Jewish Autonomous Oblast",
    # https://en.wikipedia.org/wiki/ISO_3166-2:CZ
    "CZ-31" => "South Bohemia",
    "CZ-64" => "South Moravia",
    "CZ-41" => "Karlovy Vary",
    "CZ-52" => "Hradec Králové",
    "CZ-51" => "Liberec",
    "CZ-80" => "Moravia-Silesia",
    "CZ-71" => "Olomouc",
    "CZ-53" => "Pardubice",
    "CZ-32" => "Plzeň",
    "CZ-10" => "Prague",
    "CZ-20" => "Central Bohemia",
    "CZ-42" => "Ústí nad Labem",
    "CZ-63" => "Vysočina",
    "CZ-72" => "Zlín"
  }

  for {code, en_name} <- manual_code_to_en_name do
    defp manual_en_name(unquote(code)), do: unquote(en_name)
  end

  defp manual_en_name(_code), do: nil

  defp skip?("EE-" <> _), do: true
  defp skip?("JP-" <> _), do: true
  defp skip?(_code), do: false

  def parse_cldr_xml(xml) do
    xml = String.trim(xml)

    {:ok, xml, _} =
      :xmerl_sax_parser.stream(xml,
        event_fun: &xml_event_fun/3,
        external_entities: :none
      )

    {"ldml", _,
     [{"identity", _, _}, {"localeDisplayNames", _, [{"subdivisions", _, subdivisions}]}]} = xml

    Map.new(subdivisions, fn {"subdivision", attrs, [en_name]} ->
      {"type", short_code} = Enum.find(attrs, fn {k, _} -> k == "type" end)
      # https://unicode-org.atlassian.net/browse/CLDR-17783
      {short_code, en_name |> String.replace("’", "'") |> String.replace(["²", "³"], "")}
    end)
  end

  defp xml_event_fun({:startElement, _, tag_name, _, attrs}, _location, stack) do
    attrs =
      Enum.map(attrs, fn attr ->
        {[], [], k, v} = attr
        {:unicode.characters_to_binary(k), :unicode.characters_to_binary(v)}
      end)

    [{tag_name, attrs, _content = []} | stack]
  end

  defp xml_event_fun({:characters, text}, _location, stack) do
    [{tag_name, attrs, content} | stack] = stack
    [{tag_name, attrs, [:unicode.characters_to_binary(text) | content]} | stack]
  end

  defp xml_event_fun({:endElement, _, tag_name, _}, _location, stack) do
    [{^tag_name, attrs, content} | stack] = stack
    element = {:unicode.characters_to_binary(tag_name), attrs, :lists.reverse(content)}

    case stack do
      [] ->
        element

      [{parent_name, parent_attrs, parent_content} | rest] ->
        [{parent_name, parent_attrs, [element | parent_content]} | rest]
    end
  end

  defp xml_event_fun(:startDocument, _location, :undefined), do: _stack = []
  defp xml_event_fun(:endDocument, _location, stack), do: stack
  defp xml_event_fun(_event, _location, stack), do: stack

  defp read_json(priv_path) do
    Application.app_dir(:location, priv_path)
    |> File.read!()
    |> Jason.decode!()
  end

  defp colored_put(color, message) do
    IO.puts(color <> message <> IO.ANSI.reset())
  end
end
