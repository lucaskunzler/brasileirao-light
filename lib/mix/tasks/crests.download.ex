defmodule Mix.Tasks.Crests.Download do
  @moduledoc """
  Mix task to download team crests from the API and cache them locally.
  """
  use Mix.Task

  @shortdoc "Downloads team crests"

  def run(_) do
    Mix.Task.run("app.start")
    BrasileiraoLight.CrestCache.download_all()
  end
end
