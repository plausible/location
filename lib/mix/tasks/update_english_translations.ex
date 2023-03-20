defmodule Mix.Tasks.UpdateEnglishTranslations do
  use Mix.Task

  def run(_) do
    HTTPoison.start()
    Location.Country.load()
    Location.Scraper.scrape()
  end
end
