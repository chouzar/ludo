# Gleam's interop with Erlang and Elixir

## 1. External bindings

Gleam provides a very simple FFI mechanism to reach any function
on the BEAM.

```gleam
@external(erlang, "observer", "start")
fn observer() -> ok
```

## 2. Dependencies

We can take advantage of a whole ecosystem of libraries.

```toml
cubdb = ">= 2.0.0 and < 3.0.0"
ecto = ">= 3.0.0 < 4.0.0"
phoenix = ">= 1.7.0 and < 2.0.0"
```

## 3. Using Erlang or Elixir from Gleam

Gleam tool will recognize your erlang and elixir files and
use the respective compilers to build them in your project.

```sh
gleam build
```
