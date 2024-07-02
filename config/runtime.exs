import Config

if config_env() != :prod do
  config :location, :lightweight, true
end
