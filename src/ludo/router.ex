defmodule Ludo.Web.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/", Ludo.Web do
    pipe_through(:browser)

    live("/", TicTacToeLive, :index)
  end
end
