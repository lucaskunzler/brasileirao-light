defmodule BrasileiraoLight.CrestCache do
  @moduledoc """
  Downloads and caches team crests locally.
  """
  require Logger
  alias BrasileiraoLight.Data

  @target_dir Path.join(:code.priv_dir(:brasileirao_light), "static/images/crests")

  def download_all do
    File.mkdir_p!(@target_dir)

    Data.get_matches()
    |> extract_teams()
    |> Enum.each(&download_crest/1)
  end

  defp extract_teams(matches) do
    matches
    |> Enum.flat_map(fn match -> [match.homeTeam, match.awayTeam] end)
    |> Enum.uniq_by(& &1.id)
  end

  defp download_crest(team) do
    url = team.crest
    ext = Path.extname(url)
    filename = "#{team.id}#{ext}"
    path = Path.join(@target_dir, filename)

    if File.exists?(path) do
      Logger.info("Crest for #{team.name} already exists.")
    else
      Logger.info("Downloading crest for #{team.name}...")

      case Req.get(url) do
        {:ok, %{status: 200, body: body}} ->
          File.write!(path, body)

        {:error, reason} ->
          Logger.error("Failed to download crest for #{team.name}: #{inspect(reason)}")

        _ ->
          Logger.error("Failed to download crest for #{team.name}: status not 200")
      end
    end
  end
end
