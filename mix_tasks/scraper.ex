defmodule Location.Scraper do
  @version_file Application.app_dir(:location, "/priv/version")

  def write_date_to_version() do
    File.write!(@version_file, Date.to_iso8601(Date.utc_today()))
  end
end
