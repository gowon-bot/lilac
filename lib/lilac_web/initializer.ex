defmodule LilacWeb.Initializer do
  @spec initialize :: no_return
  def initialize do
    Lilac.LastFM.API.start()
  end
end
