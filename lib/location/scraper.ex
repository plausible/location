defmodule Location.Scraper do
  use Tesla

  @version_file Application.app_dir(:location, "/priv/version")
  @postal_code_url "https://download.geonames.org/export/zip/"
  @postal_code_dest Application.app_dir(:location, "/priv/")

  def write_date_to_version() do
    File.write!(@version_file, Date.to_iso8601(Date.utc_today()))
  end

  def scrape_postal_files() do
    response = get!(@postal_code_url)
    {:ok, document} = Floki.parse_document(response.body)

    result =
      Floki.find(document, "pre")

    result = Floki.find(result, "a") |> Enum.drop(5)

    Enum.map(result, fn x ->
      [{_, [{_, _href}], [name]}] = Floki.find(x, "a")
      String.replace(name, ".zip", "")
    end)
    |> Enum.join(", ")
  end

  def fetch_postal_file(file) do
    response = get!(@postal_code_url <> "#{file}.zip")
    File.write!(@postal_code_dest <> "/#{file}.zip", response.body)
  end

  def extract_postal_file(file) do
    zip_file = Unzip.LocalFile.open("priv/#{file}.zip")

    try do
      {:ok, unzip} = Unzip.new(zip_file)

      Unzip.file_stream!(unzip, "#{file}.txt")
      |> Stream.into(File.stream!("priv/#{file}.csv"))
      |> Stream.run()
    after
      Unzip.LocalFile.close(zip_file)
    end
  end

  def fetch_postal_files(files) do
    Enum.each(files, fn file -> fetch_postal_file(file) end)
  end
end
