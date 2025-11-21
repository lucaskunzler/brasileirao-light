defmodule BrasileiraoLight.Standings do
  @moduledoc """
  Calculates the standings table based on match results.
  """

  def calculate(matches, simulated_scores \\ %{}) do
    matches
    |> apply_simulations(simulated_scores)
    |> Enum.filter(&(&1.status == "FINISHED"))
    |> Enum.reduce(%{}, &process_match/2)
    |> Map.values()
    |> sort_standings()
    |> add_position()
  end

  defp apply_simulations(matches, simulated_scores) when simulated_scores == %{}, do: matches

  defp apply_simulations(matches, simulated_scores) do
    Enum.map(matches, fn match ->
      case Map.get(simulated_scores, match.id) do
        nil ->
          match

        {home, away} ->
          %{
            match
            | status: "FINISHED",
              score: %{match.score | fullTime: %{home: home, away: away}}
          }
      end
    end)
  end

  defp process_match(match, acc) do
    home_team = match.homeTeam
    away_team = match.awayTeam
    score = match.score.fullTime

    acc
    |> update_team(home_team, score.home, score.away)
    |> update_team(away_team, score.away, score.home)
  end

  defp update_team(acc, team, goals_for, goals_against) do
    stats = Map.get(acc, team.id, initial_stats(team))

    new_stats = %{
      stats
      | played: stats.played + 1,
        wins: stats.wins + if(goals_for > goals_against, do: 1, else: 0),
        draws: stats.draws + if(goals_for == goals_against, do: 1, else: 0),
        losses: stats.losses + if(goals_for < goals_against, do: 1, else: 0),
        gf: stats.gf + goals_for,
        ga: stats.ga + goals_against,
        gd: stats.gd + (goals_for - goals_against),
        points: stats.points + points(goals_for, goals_against)
    }

    Map.put(acc, team.id, new_stats)
  end

  defp initial_stats(team) do
    %{
      id: team.id,
      name: team.shortName || team.name,
      crest: team.crest,
      points: 0,
      played: 0,
      wins: 0,
      draws: 0,
      losses: 0,
      gf: 0,
      ga: 0,
      gd: 0
    }
  end

  defp points(gf, ga) when gf > ga, do: 3
  defp points(gf, ga) when gf == ga, do: 1
  defp points(_, _), do: 0

  defp sort_standings(teams) do
    Enum.sort_by(teams, &{&1.points, &1.wins, &1.gd, &1.gf}, :desc)
  end

  defp add_position(teams) do
    teams
    |> Enum.with_index(1)
    |> Enum.map(fn {team, rank} -> Map.put(team, :position, rank) end)
  end
end
