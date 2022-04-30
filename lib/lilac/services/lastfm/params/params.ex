defmodule Lilac.LastFM.API.Params do
  alias Lilac.Requestable

  @spec build(struct, binary) :: binary
  def build(params, method) do
    params
    |> Map.from_struct()
    |> add_defaults(method)
    |> maybe_authed_params()
    |> URI.encode_query()
  end

  @spec add_defaults(map, String.t()) :: map
  defp add_defaults(params, method) do
    params
    |> Map.put(:format, "json")
    |> Map.put(:api_key, Application.fetch_env!(:last_fm, :api_key))
    |> Map.put(:method, method)
  end

  @spec maybe_authed_params(map) :: map | keyword
  defp maybe_authed_params(params) do
    if Map.has_key?(params, :sk) or Requestable.is_authed?(params.username) do
      handle_authed_params(params)
    else
      convert_username(params)
    end
  end

  defp handle_authed_params(params) do
    params =
      params
      |> Map.put(:session, params.username.session)
      |> Map.put(:username, params.username.username)

    api_sig = generate_signature(params)

    Map.to_list(params) ++ [{:api_sig, api_sig}]
  end

  @spec generate_signature(map) :: binary
  defp generate_signature(params) do
    signature =
      params
      |> Map.to_list()
      |> Enum.sort_by(fn {key, _} -> key end)
      |> Enum.filter(fn {key, _} -> key != :format end)
      |> Enum.reduce("", fn {key, value}, acc -> acc <> "#{key}#{value}" end)

    :crypto.hash(:md5, signature <> Application.fetch_env!(:last_fm, :api_secret))
    |> Base.encode16(case: :lower)
  end

  @spec convert_username(map) :: map
  defp convert_username(params) do
    if Map.has_key?(params, :username) do
      Map.put(params, :username, Requestable.from_ambiguous(params.username).username)
    else
      params
    end
  end
end
