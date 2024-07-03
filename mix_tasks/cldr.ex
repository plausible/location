defmodule Location.Cldr do
  require Cldr.Territory.Backend
  use Cldr, default_locale: "en", locales: ["en"], providers: [Cldr.Territory]
end
