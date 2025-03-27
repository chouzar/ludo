import gleam/bytes_tree
import gleam/erlang
import gleam/erlang/process.{type Selector, type Subject}
import gleam/function
import gleam/http/request.{type Request, Request}
import gleam/http/response
import gleam/json
import gleam/option.{type Option, Some}
import gleam/otp/actor
import gleam/result
import ludo/tictactoe
import ludo/web/tictactoe_app
import lustre
import lustre/attribute
import lustre/element
import lustre/element/html
import lustre/server_component
import mist.{type WebsocketConnection, type WebsocketMessage}

const static_path = "/static/lustre-server-component.mjs"

const runtime = "/assets/lustre-server-component.mjs"

pub fn start() {
  let pipeline = fn(request) { router(request) }

  // Start the Mist web server.
  mist.new(pipeline)
  |> mist.port(8088)
  |> mist.start_http()
  |> result.map(fn(subject) { process.subject_owner(subject) })
}

fn router(request) {
  case request {
    Request(path: path, ..) if path == runtime -> {
      let assert Ok(priv) = erlang.priv_directory("ludo")
      let assert Ok(file) = read(priv <> static_path)

      response.new(200)
      |> response.prepend_header("content-type", "text/javascript")
      |> response.set_body(
        file
        |> bytes_tree.from_string()
        |> mist.Bytes(),
      )
    }

    Request(path: "/tictactoe/ws", ..) -> {
      mist.websocket(
        request: request,
        on_init: fn(_websocket) {
          let assert Ok(app_instance) =
            lustre.start_actor(tictactoe_app.app(), tictactoe.new())
          socket_init(app_instance)
        },
        on_close: socket_close,
        handler: socket_update,
      )
    }

    Request(path: "/", ..) -> {
      response.new(200)
      |> response.prepend_header("content-type", "text/html")
      |> response.set_body(
        server_component("/tictactoe/ws")
        |> element.to_document_string_builder
        |> bytes_tree.from_string_tree
        |> mist.Bytes,
      )
    }

    _other -> {
      response.new(400)
      |> response.prepend_header("content-type", "text/html; charset=utf-8")
      |> response.set_body(mist.Bytes(bytes_tree.from_string("Not found")))
    }
  }
}

// -------------- Web socket helpers --------------------

fn server_component(websocket_path: String) {
  html.html([], [
    html.head([], [
      html.script(
        [
          attribute.type_("module"),
          attribute.src("/assets/lustre-server-component.mjs"),
        ],
        "",
      ),
    ]),
    html.body([], [
      element.element(
        "lustre-server-component",
        [server_component.route(websocket_path)],
        [html.p([], [html.text("slot")])],
      ),
    ]),
  ])
}

type App(message) =
  Subject(lustre.Action(message, lustre.ServerComponent))

fn socket_init(
  app_instance,
) -> #(App(message), Option(Selector(lustre.Patch(message)))) {
  let self = process.new_subject()

  process.send(
    app_instance,
    server_component.subscribe(
      // server components can have many connected clients, so we need a way to
      // identify this client.
      "ws",
      // this callback is called whenever the server component has a new patch
      // to send to the client. here we json encode that patch and send it to
      // via the websocket connection.
      //
      // a more involved version would have us sending the patch to this socket's
      // subject, and then it could be handled (perhaps with some other work) in
      // the `mist.Custom` branch of `socket_update` below.
      process.send(self, _),
    ),
  )

  #(
    // we store the server component's `Subject` as this socket's state so we
    // can shut it down when the socket is closed.
    app_instance,
    Some(process.selecting(process.new_selector(), self, function.identity)),
  )
}

fn socket_update(
  app: App(message),
  conn: WebsocketConnection,
  msg: WebsocketMessage(lustre.Patch(message)),
) {
  case msg {
    mist.Text(json) -> {
      // we attempt to decode the incoming text as an action to send to our
      // server component runtime.
      let action = json.decode(json, server_component.decode_action)

      case action {
        Ok(action) -> process.send(app, action)
        Error(_) -> Nil
      }

      actor.continue(app)
    }

    mist.Binary(_) -> {
      actor.continue(app)
    }

    mist.Custom(patch) -> {
      let assert Ok(_) =
        patch
        |> server_component.encode_patch
        |> json.to_string
        |> mist.send_text_frame(conn, _)

      actor.continue(app)
    }

    mist.Closed | mist.Shutdown -> {
      actor.Stop(process.Normal)
    }
  }
}

fn socket_close(app: App(message)) {
  process.send(app, lustre.shutdown())
}

type Reason

@external(erlang, "file", "read_file")
fn read(path: String) -> Result(String, Reason)
