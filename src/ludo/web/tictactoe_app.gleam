import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import ludo/tictactoe
import lustre
import lustre/attribute.{class, data}
import lustre/element.{fragment, none}
import lustre/element/html.{div, h1, style, text}
import lustre/event

// MAIN ------------------------------------------------------------------------

pub fn app() {
  lustre.simple(init, update, view)
}

// MODEL -----------------------------------------------------------------------

pub type Model {
  Model(game: tictactoe.Game, end: Option(tictactoe.End))
}

fn init(game: tictactoe.Game) -> Model {
  Model(game: game, end: None)
}

// UPDATE ----------------------------------------------------------------------

pub opaque type Msg {
  Mark(x: Int, y: Int)
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    Mark(x, y) -> {
      case tictactoe.mark(model.game, x, y) {
        Ok(game) -> {
          Model(game: game, end: update_end(game))
        }

        Error(_error) -> {
          model
        }
      }
    }
  }
}

fn update_end(game: tictactoe.Game) {
  case tictactoe.end(game) {
    Ok(end) -> Some(end)
    Error(Nil) -> None
  }
}

// VIEW ------------------------------------------------------------------------

fn view(model: Model) -> element.Element(Msg) {
  fragment([
    div([class("win-block")], [h1([], [view_win(model)])]),
    div([class("center")], [div([class("grid")], view_grid(model))]),
    style([], css),
  ])
}

fn view_win(model: Model) {
  case model.end {
    Some(tictactoe.Win(tictactoe.X)) -> text("Game! X 🎉")
    Some(tictactoe.Win(tictactoe.O)) -> text("Game! O 🎉")
    Some(tictactoe.Draw) -> text("Draw! 👏")
    None -> none()
  }
}

fn view_grid(model: Model) {
  use x <- list.flat_map([1, 2, 3])
  use y <- list.map([1, 2, 3])

  let assert Ok(value) = dict.get(model.game.grid, #(x, y))

  let attributes = [
    data("value-x", int.to_string(x)),
    data("value-y", int.to_string(y)),
  ]

  let attributes = case value {
    Some(tictactoe.X) -> [class("mark-x"), ..attributes]
    Some(tictactoe.O) -> [class("mark-o"), ..attributes]
    None -> attributes
  }

  let attributes = case model.end {
    Some(_) -> attributes
    None -> [event.on_click(Mark(x, y)), ..attributes]
  }

  let mark = case value {
    Some(tictactoe.X) -> text("X")
    Some(tictactoe.O) -> text("O")
    None -> none()
  }

  div(attributes, [mark])
}

const css = "
.grid {
  height: 750px;
  width: 750px;
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  grid-template-rows: 1fr 1fr 1fr;
  background-color: #292d3e;
  gap: 5px;
}
.grid > div {
  background-color: #fffefb;
  text-align: center;
  padding: 61px 0px;
  font-size: 100px;
  font-family: verdana;
}
.mark-x {
  color: #ffaff3;
}
.mark-o {
  color: #4e2a8e;
}
.center {
  display: flex;
  justify-content: center;
  height: 100vh;
}
.win-block {
  padding-top: 16px;
  padding-bottom: 16px;
  height: 160;
}
.win-block > h1 {
  font-family: cursive;
  text-align: center;
  font-size: 100px;
  margin: 0;
}
"
