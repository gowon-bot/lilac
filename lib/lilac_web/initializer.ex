defmodule LilacWeb.Initializer do
  @spec initialize :: no_return
  def initialize do
    print_startup_message()
    Lilac.LastFM.API.start()
  end

  @spec print_startup_message :: no_return
  def print_startup_message do
    IO.puts(
      IO.ANSI.cyan() <>
        """
        888       d8b  888
        888       Y8P  888
        888            888
        888       888  888   8888b.    .d8888b
        888       888  888      "88b  d88P"
        888       888  888  .d888888  888
        888       888  888  888  888  Y88b.
        88888888  888  888  "Y888888   "Y8888P  라일락
        ==============================================
        """ <> IO.ANSI.reset()
    )
  end
end
