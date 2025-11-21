defmodule BrasileiraoLightWeb.StandingsLive do
  use BrasileiraoLightWeb, :live_view

  alias BrasileiraoLight.{Data, Matches, Standings}

  def mount(_params, _session, socket) do
    case Data.load() do
      {:ok, data} ->
        matches = data.matches
        current_round = Matches.current_round(matches)
        standings = Standings.calculate(matches)
        all_matches = Matches.list_matches(matches)

        {:ok,
         socket
         |> assign(:standings, standings)
         |> assign(:all_matches, all_matches)
         |> assign(:current_round, current_round)
         |> assign(:simulated_scores, %{})
         |> assign(:active_tab, :standings)}

      {:error, _reason} ->
        {:ok,
         socket
         |> assign(:standings, [])
         |> assign(:all_matches, [])
         |> assign(:current_round, 1)
         |> assign(:simulated_scores, %{})
         |> assign(:active_tab, :standings)
         |> put_flash(:error, "Failed to load data")}
    end
  end

  def handle_event("set_tab", %{"tab" => tab}, socket) do
    {:noreply, assign(socket, :active_tab, String.to_atom(tab))}
  end

  def handle_event("prev_round", _, socket) do
    new_round = max(1, socket.assigns.current_round - 1)
    {:noreply, assign(socket, :current_round, new_round)}
  end

  def handle_event("next_round", _, socket) do
    max_round = socket.assigns.all_matches |> Enum.map(& &1.matchday) |> Enum.max()
    new_round = min(max_round, socket.assigns.current_round + 1)
    {:noreply, assign(socket, :current_round, new_round)}
  end

  def handle_event(
        "simulate_result",
        %{"match_id" => match_id, "home" => home, "away" => away},
        socket
      ) do
    with {home_int, ""} <- Integer.parse(home),
         {away_int, ""} <- Integer.parse(away),
         match_id_int <- String.to_integer(match_id) do
      simulated_scores =
        Map.put(socket.assigns.simulated_scores, match_id_int, {home_int, away_int})

      standings = Standings.calculate(socket.assigns.all_matches, simulated_scores)

      {:noreply,
       socket
       |> assign(:simulated_scores, simulated_scores)
       |> assign(:standings, standings)}
    else
      _ -> {:noreply, socket}
    end
  end

  def handle_event("clear_simulation", %{"match_id" => match_id}, socket) do
    simulated_scores = Map.delete(socket.assigns.simulated_scores, String.to_integer(match_id))
    standings = Standings.calculate(socket.assigns.all_matches, simulated_scores)

    {:noreply,
     socket
     |> assign(:simulated_scores, simulated_scores)
     |> assign(:standings, standings)}
  end

  def render(assigns) do
    ~H"""
    <div class="lg:max-w-7xl max-w-md mx-auto bg-gray-50 min-h-screen flex flex-col font-sans text-gray-900">
      <header class="bg-green-600 text-white p-4 shadow-md sticky top-0 z-10">
        <h1 class="text-xl font-bold text-center">Brasileirão 2025</h1>
      </header>

      <div class="flex bg-white shadow-sm mb-4 sticky top-14 z-10 lg:hidden">
        <button
          phx-click="set_tab"
          phx-value-tab="standings"
          class={"flex-1 py-3 text-sm font-medium border-b-2 transition-colors #{if @active_tab == :standings, do: "border-green-600 text-green-700", else: "border-transparent text-gray-500 hover:text-gray-700"}"}
        >
          Tabela
        </button>
        <button
          phx-click="set_tab"
          phx-value-tab="matches"
          class={"flex-1 py-3 text-sm font-medium border-b-2 transition-colors #{if @active_tab == :matches, do: "border-green-600 text-green-700", else: "border-transparent text-gray-500 hover:text-gray-700"}"}
        >
          Jogos
        </button>
      </div>

      <main class="flex-1 p-2 lg:p-4">
        <div class="hidden lg:grid lg:grid-cols-2 lg:gap-4">
          <div>
            <h2 class="text-lg font-bold mb-3 text-gray-800">Classificação</h2>
            <.standings_table standings={@standings} />
          </div>
          <div>
            <h2 class="text-lg font-bold mb-3 text-gray-800">Rodada {@current_round}</h2>
            <.match_list
              all_matches={@all_matches}
              current_round={@current_round}
              simulated_scores={@simulated_scores}
            />
          </div>
        </div>

        <div class="lg:hidden">
          <%= if @active_tab == :standings do %>
            <.standings_table standings={@standings} />
          <% else %>
            <.match_list
              all_matches={@all_matches}
              current_round={@current_round}
              simulated_scores={@simulated_scores}
            />
          <% end %>
        </div>
      </main>
    </div>
    """
  end

  defp crest_path(team) do
    ext = Path.extname(team.crest)
    "/images/crests/#{team.id}#{ext}"
  end

  def standings_table(assigns) do
    ~H"""
    <div class="bg-white rounded-lg shadow overflow-hidden">
      <table class="w-full text-xs">
        <thead class="bg-gray-100 text-gray-600 border-b border-gray-200">
          <tr>
            <th class="p-2 text-center w-8">#</th>
            <th class="p-2 text-left">Time</th>
            <th class="p-2 text-center font-bold">P</th>
            <th class="p-2 text-center text-gray-400">J</th>
            <th class="p-2 text-center text-gray-400">V</th>
            <th class="p-2 text-center text-gray-400">E</th>
            <th class="p-2 text-center text-gray-400">D</th>
            <th class="p-2 text-center text-gray-400">SG</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          <%= for team <- @standings do %>
            <tr class={"#{row_class(team.position)}"}>
              <td class={"p-2 text-center font-medium #{position_color(team.position)}"}>
                {team.position}
              </td>
              <td class="p-2 flex items-center space-x-2">
                <img
                  src={crest_path(team)}
                  class="w-5 h-5 object-contain"
                  alt={team.name}
                  loading="lazy"
                />
                <span class="font-semibold truncate max-w-[100px]">{team.name}</span>
              </td>
              <td class="p-2 text-center font-bold bg-gray-50">{team.points}</td>
              <td class="p-2 text-center text-gray-500">{team.played}</td>
              <td class="p-2 text-center text-gray-400">{team.wins}</td>
              <td class="p-2 text-center text-gray-400">{team.draws}</td>
              <td class="p-2 text-center text-gray-400">{team.losses}</td>
              <td class="p-2 text-center text-gray-400">{team.gd}</td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    <div class="mt-4 px-2 text-[10px] text-gray-500 space-y-1">
      <div class="flex items-center">
        <span class="w-2 h-2 rounded-full bg-blue-500 mr-2"></span> Libertadores
      </div>
      <div class="flex items-center">
        <span class="w-2 h-2 rounded-full bg-cyan-400 mr-2"></span> Pré-Libertadores
      </div>
      <div class="flex items-center">
        <span class="w-2 h-2 rounded-full bg-green-500 mr-2"></span> Sul-Americana
      </div>
      <div class="flex items-center">
        <span class="w-2 h-2 rounded-full bg-red-500 mr-2"></span> Rebaixamento
      </div>
    </div>
    """
  end

  def match_list(assigns) do
    ~H"""
    <div class="space-y-3">
      <div class="flex items-center justify-between bg-white rounded-lg shadow p-3">
        <button
          phx-click="prev_round"
          class="px-3 py-1 text-sm font-medium text-gray-700 bg-gray-100 rounded hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed"
          disabled={@current_round <= 1}
        >
          ← Anterior
        </button>
        <div class="text-sm font-bold text-gray-700">
          Rodada {@current_round}
        </div>
        <button
          phx-click="next_round"
          class="px-3 py-1 text-sm font-medium text-gray-700 bg-gray-100 rounded hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed"
          disabled={@current_round >= @all_matches |> Enum.map(& &1.matchday) |> Enum.max()}
        >
          Próxima →
        </button>
      </div>

      <%= for match <- filter_matches_by_round(@all_matches, @current_round) do %>
        <div class="bg-white rounded-lg shadow overflow-hidden">
          <div class="p-3 flex items-center justify-between">
            <div class="flex items-center space-x-2 w-1/3 justify-end">
              <span class="text-xs font-medium truncate text-right">
                {match.homeTeam.shortName}
              </span>
              <img src={crest_path(match.homeTeam)} class="w-6 h-6 object-contain" loading="lazy" />
            </div>

            <div class="flex flex-col items-center w-1/6">
              <%= if match.status == "FINISHED" do %>
                <div class="text-sm font-bold bg-gray-100 px-2 py-0.5 rounded">
                  {match.score.fullTime.home} x {match.score.fullTime.away}
                </div>
                <div class="text-[10px] text-gray-400 mt-1">
                  {format_date_short(match.utcDate)}
                </div>
              <% else %>
                <%= if Map.has_key?(@simulated_scores, match.id) do %>
                  <% {home, away} = @simulated_scores[match.id] %>
                  <div class="text-sm font-bold bg-green-100 px-2 py-0.5 rounded">
                    {home} x {away}
                  </div>
                  <button
                    phx-click="clear_simulation"
                    phx-value-match_id={match.id}
                    class="text-[10px] text-red-500 mt-1 hover:underline"
                  >
                    Limpar
                  </button>
                <% else %>
                  <div class="flex flex-col items-center gap-1">
                    <div class="flex gap-1 items-center">
                      <button
                        phx-click="simulate_result"
                        phx-value-match_id={match.id}
                        phx-value-home="1"
                        phx-value-away="0"
                        class="px-2 py-1 text-xs font-medium text-gray-700 bg-gray-100 rounded hover:bg-blue-100 hover:text-blue-700 transition-colors"
                        title="Vitória Casa"
                      >
                        1x0
                      </button>
                      <button
                        phx-click="simulate_result"
                        phx-value-match_id={match.id}
                        phx-value-home="0"
                        phx-value-away="0"
                        class="px-2 py-1 text-xs font-medium text-gray-700 bg-gray-100 rounded hover:bg-yellow-100 hover:text-yellow-700 transition-colors"
                        title="Empate"
                      >
                        0x0
                      </button>
                      <button
                        phx-click="simulate_result"
                        phx-value-match_id={match.id}
                        phx-value-home="0"
                        phx-value-away="1"
                        class="px-2 py-1 text-xs font-medium text-gray-700 bg-gray-100 rounded hover:bg-red-100 hover:text-red-700 transition-colors"
                        title="Vitória Fora"
                      >
                        0x1
                      </button>
                    </div>
                    <div class="text-[10px] text-gray-400">
                      {format_time(match.utcDate)} - {format_date_short(match.utcDate)}
                    </div>
                  </div>
                <% end %>
              <% end %>
            </div>

            <div class="flex items-center space-x-2 w-1/3">
              <img src={crest_path(match.awayTeam)} class="w-6 h-6 object-contain" loading="lazy" />
              <span class="text-xs font-medium truncate">{match.awayTeam.shortName}</span>
            </div>
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  defp row_class(position) do
    cond do
      position <= 4 -> "bg-blue-100"
      position <= 6 -> "bg-cyan-100"
      position <= 12 -> "bg-green-100"
      position >= 17 -> "bg-red-100"
      true -> ""
    end
  end

  defp position_color(position) do
    cond do
      position <= 4 -> "text-blue-600"
      position <= 6 -> "text-cyan-600"
      position <= 12 -> "text-green-600"
      position >= 17 -> "text-red-600"
      true -> "text-gray-400"
    end
  end

  defp filter_matches_by_round(matches, round) do
    matches
    |> Enum.filter(&(&1.matchday == round))
    |> Enum.sort_by(& &1.utcDate)
  end

  defp format_date_short(date_str) do
    case Date.from_iso8601(String.slice(date_str, 0, 10)) do
      {:ok, date} -> Calendar.strftime(date, "%d/%m")
      _ -> ""
    end
  end

  defp format_time(utc_date) do
    case DateTime.from_iso8601(utc_date) do
      {:ok, dt, _} ->
        dt
        |> DateTime.add(-3, :hour)
        |> Calendar.strftime("%H:%M")

      _ ->
        ""
    end
  end
end
