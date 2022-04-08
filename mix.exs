defmodule Location.MixProject do
  use Mix.Project

  def project do
    [
      app: :location,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps()
    ]
  end

  defp description do
    """
    Elixir library for accessing ISO3166-1 (country) and ISO3166-2 (subdivision) data as well as geoname data for cities. Source data comes from the upstream [debian iso-codes](https://salsa.debian.org/iso-codes-team/iso-codes) package.
    """
  end

  defp package do
    [
      files: ["lib", "priv", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Uku Taht"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/plausible/location"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.3"},
      {:floki, "~> 0.31.0", only: [:dev, :test]},
      {:httpoison, "~> 1.8", only: [:dev, :test]},
      {:flow, "~> 1.0", only: [:dev, :test]}
    ]
  end
end
