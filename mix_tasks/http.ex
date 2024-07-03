defmodule Location.HTTP do
  @moduledoc false

  def get!(url, headers \\ []) do
    headers = for {field, val} <- headers, do: {String.to_charlist(field), val}

    http_opts = [
      ssl: [
        verify: :verify_peer,
        depth: 4,
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ],
        cacerts: :public_key.cacerts_get()
      ],
      timeout: :timer.seconds(15),
      connect_timeout: :timer.seconds(15)
    ]

    opts = [
      body_format: :binary
    ]

    case :httpc.request(:get, {url, headers}, http_opts, opts) do
      {:ok, {{_, status, _}, headers, body}} ->
        headers = for {field, val} <- headers, do: {List.to_string(field), List.to_string(val)}
        {status, headers, body}

      {:error, reason} ->
        raise "failed GET #{url} with #{inspect(reason)}"
    end
  end
end
