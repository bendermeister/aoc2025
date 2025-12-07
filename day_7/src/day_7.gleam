import gleam/bool
import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/pair
import gleam/result
import gleam/string
import simplifile
import util/field
import util/point

pub type Field {
  Empty
  Splitter
  Start
}

pub type Message {
  Push(key: point.Point, value: Int)
  Pop(reply_to: process.Subject(Result(Int, Nil)), key: point.Point)
  Stop
}

pub fn on_message(state: dict.Dict(point.Point, Int), message: Message) {
  case message {
    Pop(reply_to:, key:) -> {
      state
      |> dict.get(key)
      |> actor.send(reply_to, _)

      actor.continue(state)
    }
    Push(key:, value:) ->
      state
      |> dict.insert(key, value)
      |> actor.continue
    Stop -> actor.stop()
  }
}

pub fn count_splits(
  map: dict.Dict(point.Point, Field),
  acc: Int,
  beams: List(point.Point),
) -> Int {
  use <- bool.guard(when: list.is_empty(beams), return: acc)

  let beams =
    beams
    |> list.map(point.add(_, point.new(0, 1)))
    |> list.map(fn(x) {
      map
      |> dict.get(x)
      |> result.map(pair.new(_, x))
    })
    |> result.partition()
    |> pair.first()

  let acc =
    beams
    |> list.map(pair.first)
    |> list.count(fn(x) { x == Splitter })
    |> int.add(acc)

  beams
  |> list.flat_map(fn(x) {
    let #(field, beam) = x
    case field {
      Splitter -> [
        point.add(beam, point.new(-1, 0)),
        point.add(beam, point.new(1, 0)),
      ]
      _ -> [beam]
    }
  })
  |> list.filter(fn(x) { x.x >= 0 })
  |> list.filter(fn(x) { x.y >= 0 })
  |> list.unique
  |> count_splits(map, acc, _)
}

pub fn task_1(input: String) {
  let map =
    input
    |> field.from_string()
    |> field.points()
    |> list.map(
      pair.map_second(_, fn(x) {
        case x {
          "." -> Empty
          "^" -> Splitter
          "S" -> Start
          _ -> panic
        }
      }),
    )

  let start =
    map
    |> list.find(fn(x) { x.1 == Start })
    |> result.map(pair.first)
    |> result.lazy_unwrap(fn() { panic })

  let map = map |> dict.from_list()

  count_splits(map, 0, [start])
}

pub fn count_paths(
  actor,
  beam: point.Point,
  map: dict.Dict(point.Point, Field),
) -> Int {
  let mem = actor.call(actor, 20_000, Pop(_, beam))
  use <- result.lazy_unwrap(mem)

  let beam = beam |> point.add(point.new(0, 1))
  let field = dict.get(map, beam)

  use <- bool.guard(when: field == Error(Nil), return: 1)
  let assert Ok(field) = field

  let result = case field {
    Splitter -> {
      let left =
        beam
        |> point.add(point.new(-1, 0))
        |> count_paths(actor, _, map)
      let right =
        beam
        |> point.add(point.new(1, 0))
        |> count_paths(actor, _, map)
      left + right
    }
    Start | Empty -> count_paths(actor, beam, map)
  }

  actor.send(actor, Push(beam, result))

  result
}

pub fn task_2(actor, input: String) {
  let map =
    input
    |> field.from_string()
    |> field.points
    |> list.map(
      pair.map_second(_, fn(x) {
        case x {
          "." -> Empty
          "S" -> Start
          "^" -> Splitter
          _ -> panic
        }
      }),
    )

  let assert Ok(start) =
    map
    |> list.find(fn(x) { x.1 == Start })
    |> result.map(pair.first)

  let map = map |> dict.from_list()

  count_paths(actor, start, map)
}

pub fn main() -> Nil {
  let assert Ok(actor) =
    actor.new(dict.new())
    |> actor.on_message(on_message)
    |> actor.start()
  let actor = actor.data

  let input =
    "
.......S.......
...............
.......^.......
...............
......^.^......
...............
.....^.^.^.....
...............
....^.^...^....
...............
...^.^...^.^...
...............
..^...^.....^..
...............
.^.^.^.^.^...^.
...............
    "
  let assert Ok(input) = simplifile.read("input.txt")
  io.print("Task 1: ")
  input |> task_1() |> int.to_string |> io.println
  io.print("Task 2: ")
  input |> task_2(actor, _) |> int.to_string |> io.println

  actor.send(actor, Stop)
}
