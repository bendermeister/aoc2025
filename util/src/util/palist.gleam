import gleam/bool
import gleam/erlang/process
import gleam/int
import gleam/list
import gleam/otp/actor
import gleam/pair

fn list_batch(list: List(a), size: Int) -> List(List(a)) {
  case list.split(list, size) {
    #(head, []) -> [head]
    #(head, tail) -> [head, ..list_batch(tail, size)]
  }
}

fn list_index_and_batch(list: List(a), size: Int) -> List(List(#(Int, a))) {
  list
  |> list.index_map(fn(x, index) { #(index, x) })
  |> list_batch(size)
}

type State(b) {
  State(remaining_batches: Int, accumulator: List(#(Int, b)))
}

pub fn map(list: List(a), batch_size: Int, func: fn(a) -> b) {
  use <- bool.guard(when: list.is_empty(list), return: [])

  let result = process.new_subject()
  let batches = list |> list_index_and_batch(batch_size)

  let on_message = fn(state: State(b), data: List(#(Int, b))) {
    let remaining_batches = state.remaining_batches - 1
    let accumulator = state.accumulator |> list.append(data)
    case remaining_batches <= 0 {
      False -> actor.continue(State(remaining_batches:, accumulator:))
      True -> {
        accumulator
        |> list.sort(fn(a, b) { int.compare(a.0, b.0) })
        |> list.map(pair.second)
        |> process.send(result, _)

        actor.stop()
      }
    }
  }

  let assert Ok(actor) =
    batches
    |> list.length()
    |> State(remaining_batches: _, accumulator: [])
    |> actor.new()
    |> actor.on_message(on_message)
    |> actor.start()

  batches
  |> list.map(fn(batch) {
    process.spawn(fn() {
      batch
      |> list.map(pair.map_second(_, func))
      |> process.send(actor.data, _)
    })
  })

  process.receive_forever(result)
}
