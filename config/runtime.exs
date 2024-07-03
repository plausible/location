import Config

config :ex_cldr, default_backend: Location.Cldr

if config_env() != :prod do
  config :location, :lightweight, true
  config :ex_cldr, default_backend: Location.Cldr
end
