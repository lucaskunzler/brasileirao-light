defmodule BrasileiraoLight.Matches do
  @moduledoc """
  Handles match filtering and sorting.
  """

  def list_matches(matches) do
    matches
    |> Enum.sort_by(& &1.utcDate)
  end

  def filter_by_status(matches, status) do
    Enum.filter(matches, &(&1.status == status))
  end

  def current_round(matches) do
    today = Date.utc_today()

    # Find the first unfinished match
    matches
    |> Enum.sort_by(& &1.utcDate)
    |> Enum.find(fn match ->
      match_date = match.utcDate |> String.slice(0, 10) |> Date.from_iso8601!()
      match.status != "FINISHED" and Date.compare(match_date, today) in [:eq, :gt]
    end)
    |> case do
      nil ->
        # All matches finished, return last round
        matches |> Enum.map(& &1.matchday) |> Enum.max()

      match ->
        match.matchday
    end
  end
end
