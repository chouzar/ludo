defmodule Ludo.Web.Endpoint do
  use Phoenix.Endpoint, otp_app: :ludo
  socket("/live", Phoenix.LiveView.Socket)
  plug(Ludo.Web.Router)
end

defmodule Ludo.Web.Supervisor do
  def start() do
    config()

    children = [
      Ludo.Web.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  defp config() do
    Application.put_env(:ludo, Ludo.Web.Endpoint,
      http: [ip: {127, 0, 0, 1}, port: 5001],
      server: true,
      live_view: [signing_salt: "aaaaaaaa"],
      secret_key_base: String.duplicate("a", 64)
    )
  end
end

defmodule Ludo.Web.LayoutLive do
  use Phoenix.LiveView

  defp phx_vsn, do: Application.spec(:phoenix, :vsn)
  defp lv_vsn, do: Application.spec(:phoenix_live_view, :vsn)

  def render("live.html", assigns) do
    ~H"""
    <main>
      <%= @inner_content %>
    </main>
    <script src={"https://cdn.jsdelivr.net/npm/phoenix@#{phx_vsn()}/priv/static/phoenix.min.js"}></script>
    <script src={"https://cdn.jsdelivr.net/npm/phoenix_live_view@#{lv_vsn()}/priv/static/phoenix_live_view.min.js"}></script>
    <script>
      let liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket)
      liveSocket.connect()
    </script>
    """
  end
end

defmodule Ludo.ErrorView do
  def render(template, _), do: Phoenix.Controller.status_message_from_template(template)
end
