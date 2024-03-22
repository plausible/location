# Location

Elixir library for accessing ISO3166-1 (country) and ISO3166-2 (subdivision) data as well as geoname data for cities and postal code data. Source data comes from the upstream [debian iso-codes](https://salsa.debian.org/iso-codes-team/iso-codes) package and the [Geonames](http://www.geonames.org/) project.



### Countries

The data for countries comes primarily from the [debian iso-codes](https://salsa.debian.org/iso-codes-team/iso-codes) package. The data file for that is stored in `priv/iso_3166-1.json`. We do
manually add some data that is missing from upstream. Overrides can be found in `priv/override/iso_3166-1.json`

### Subdivisions

The data for subdivisions comes primarily from the [debian iso-codes](https://salsa.debian.org/iso-codes-team/iso-codes) package. The data file for that is stored in `priv/iso_3166-2.json`. The
subdivision names in this file are mostly in local language (i.e. Wien instead of Vienna). English translations are obtained from Wikipedia using a scraper. The translations found in `priv/iso_3166-2.en-translations.json` are used when available instead of the original name.

We also add some data manually that is missing from upstream. Overrides can be found in `priv/override/iso_3166-2.json`

### Cities

The data for cities comes from the [geonames](http://www.geonames.org/) project. This project has scripts to download the main `allCountries.txt` file or individual country files. If allCountries is chosen is then processed to make it smaller
(from 1.3GB to about 130MB). Still, the resulting file is quite large so we also provide a city database based on the smaller `cities500.txt` file or one choose the --source option.

### Postal Codes
The data for postal codes comes from the [geonames](http://www.geonames.org/) project. This project has scripts to download all or individual postal code files via the --source option.

#### Postal Code Helpers
Postal codes can be downloaded 