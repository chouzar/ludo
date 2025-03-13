import gleam/erlang/process
import gleam/otp/static_supervisor as sup

pub fn main() {
  let _supervisor =
    sup.new(sup.OneForOne)
    |> sup.add(sup.worker_child("web", phoenix_endpoint))
    |> sup.start_link

  observer()

  // The web server runs in new Erlang process, so put this one to sleep while
  // it works concurrently.
  process.sleep_forever()
}

@external(erlang, "observer", "start")
fn observer() -> x

@external(erlang, "Elixir.Ludo.Web.Supervisor", "start")
fn phoenix_endpoint() -> phoenix_endpoint
