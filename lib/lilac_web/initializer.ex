defmodule LilacWeb.Initializer do
  @spec initialize :: no_return
  def initialize do
    Lilac.Services.LastFMAPI.start()
  end
end
