defmodule LilacWeb.Router do
  use LilacWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", LilacWeb do
    pipe_through :api
  end
end
