import gleam/erlang/process
import gleam/list
import gleam/otp/actor
import gleam/result
import mala

pub type Message(key, value) {
  Stop
  Get(reply_to: process.Subject(Result(value, Nil)), key: key)
  Push(key: key, value: value)
}

pub fn new(callback) -> b {
  let assert Ok(actor) =
    actor.new(mala.new())
    |> actor.on_message(on_message)
    |> actor.start()

  let result = callback(actor.data)
  actor.send(actor.data, Stop)
  result
}

pub fn memoize(
  actor: process.Subject(Message(a, b)),
  key: a,
  callback: fn() -> b,
) -> b {
  case actor.call(actor, 20_000, Get(_, key)) {
    Ok(value) -> value
    Error(_) -> {
      let value = callback()
      actor.send(actor, Push(key, value))
      value
    }
  }
}

fn on_message(bag, message: Message(key, value)) {
  case message {
    Get(reply_to:, key:) -> {
      bag
      |> mala.get(key)
      |> result.unwrap([])
      |> list.first()
      |> process.send(reply_to, _)

      actor.continue(bag)
    }
    Push(key:, value:) -> {
      let assert Ok(_) = bag |> mala.delete_key(key)
      let assert Ok(_) = bag |> mala.insert(key, value)
      bag |> actor.continue
    }
    Stop -> {
      bag |> mala.drop_table()
      actor.stop()
    }
  }
}
