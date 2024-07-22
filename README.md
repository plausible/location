# Location

Elixir library for accessing ISO3166-1 (country) and ISO3166-2 (subdivision) data as well as geoname data for cities. Source data comes from the upstream [debian iso-codes](https://salsa.debian.org/iso-codes-team/iso-codes) package and the [Geonames](http://www.geonames.org/) project.

### Countries

The data for countries comes primarily from the [debian iso-codes](https://salsa.debian.org/iso-codes-team/iso-codes) package. The data file for that is stored in `priv/iso_3166-1.json`. We do
manually add some data that is missing from upstream. Overrides can be found in `priv/override/iso_3166-1.json`

### Subdivisions

The data for subdivisions comes primarily from the [debian iso-codes](https://salsa.debian.org/iso-codes-team/iso-codes) package. The data file for that is stored in `priv/iso_3166-2.json`. The subdivision names in this file are mostly in local language (i.e. Wien instead of Vienna). English translations are obtained from CLDR and Wikipedia. The translations found in `priv/iso_3166-2.en-translations.json` are used when available instead of the original name.

### Cities

The data for cities comes from the [geonames](http://www.geonames.org/) project. This project has scripts to download the main `allCountries.txt` file. It is then processed to make it smaller
(from 1.3GB to about 130MB). Still, the resulting file is quite large so we also provide a city database based on the smaller `cities500.txt` file.
