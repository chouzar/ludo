defmodule Ludo.Web.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/games", Ludo.Web do
    pipe_through(:browser)

    live("/tictactoe", TicTacToeLive, :index)
  end
end
