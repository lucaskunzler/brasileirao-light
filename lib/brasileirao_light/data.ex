defmodule BrasileiraoLight.Data do
  @moduledoc """
  Handles loading of the static JSON data.
  """

  @data_path Path.join(:code.priv_dir(:brasileirao_light), "data/2025.json")

  @key :brasileirao_data

  def load do
    case :persistent_term.get(@key, nil) do
      nil -> load_from_file()
      data -> {:ok, data}
    end
  end

  def warmup do
    case load_from_file() do
      {:ok, data} -> :persistent_term.put(@key, data)
      _ -> :ok
    end
  end

  defp load_from_file do
    with {:ok, body} <- File.read(@data_path),
         {:ok, json} <- Jason.decode(body, keys: :atoms) do
      {:ok, json}
    else
      err -> err
    end
  end

  def get_matches do
    case load() do
      {:ok, %{matches: matches}} -> matches
      _ -> []
    end
  end
end
