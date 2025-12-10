import gleam/bool
import gleam/dict
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import simplifile
import util/palist

pub type Configuration {
  Configuration(
    desired_state: dict.Dict(Int, Bool),
    commands: List(List(Int)),
    jolts: List(Int),
  )
}

pub fn parse_line(input: String) -> #(List(Bool), List(List(Int)), List(Int)) {
  let input =
    input
    |> string.trim()
    |> string.drop_start(1)
    |> string.drop_end(1)

  let assert Ok(#(lights, rest)) = input |> string.split_once("]")
  let assert Ok(#(buttons, jolts)) = rest |> string.split_once("{")

  let lights =
    lights
    |> string.trim()
    |> string.to_graphemes()
    |> list.map(fn(x) {
      case x {
        "#" -> True
        "." -> False
        _ -> panic
      }
    })

  let buttons =
    buttons
    |> string.trim()
    |> string.split(" ")
    |> list.map(fn(x) {
      x
      |> string.drop_start(1)
      |> string.drop_end(1)
      |> string.split(",")
      |> list.map(int.parse)
      |> result.partition()
      |> pair.first()
      |> list.reverse()
    })

  let jolts =
    jolts
    |> string.trim()
    |> string.split(",")
    |> list.map(int.parse)
    |> result.partition
    |> pair.first
    |> list.reverse

  #(lights, buttons, jolts)
}

pub fn parse(input: String) -> List(#(List(Bool), List(List(Int)), List(Int))) {
  input
  |> string.trim()
  |> string.split("\n")
  |> list.map(parse_line)
}

pub fn button_press(buttons: List(List(Int)), number_of_lights: Int) {
  let acc =
    buttons
    |> list.flatten()
    |> list.fold(dict.new(), fn(acc, button) {
      acc
      |> dict.get(button)
      |> result.unwrap(False)
      |> bool.negate
      |> dict.insert(acc, button, _)
    })

  list.range(0, number_of_lights - 1)
  |> list.map(fn(x) { dict.get(acc, x) |> result.unwrap(False) })
}

pub fn button_press_2(buttons: List(Int), number_of_lights: Int) {
  let acc =
    buttons
    |> list.fold(dict.new(), fn(acc, button) {
      acc
      |> dict.get(button)
      |> result.unwrap(0)
      |> int.add(1)
      |> dict.insert(acc, button, _)
    })

  list.range(0, number_of_lights - 1)
  |> list.map(fn(x) { dict.get(acc, x) |> result.unwrap(0) })
}

pub fn task_1(input: List(#(List(Bool), List(List(Int)), List(Int)))) {
  input
  |> list.map(fn(x) {
    let #(lights, buttons, _) = x
    let lights_length = lights |> list.length

    list.range(1, buttons |> list.length)
    |> list.drop_while(fn(take) {
      buttons
      |> list.combinations(take)
      |> list.all(fn(perm) { button_press(perm, lights_length) != lights })
    })
    |> list.first()
    |> result.unwrap(-1)
  })
  |> int.sum()
}

pub fn get_neighbors(
  jolts: List(Int),
  buttons: List(List(Int)),
  cealing: List(Int),
) -> List(List(Int)) {
  buttons
  |> list.map(list.map2(_, jolts, int.add))
  |> list.filter(fn(jolts_new) {
    list.map2(cealing, jolts_new, int.subtract)
    |> list.any(fn(x) { x < 0 })
    |> bool.negate
  })
}

// pub fn dijkstra(
//   nodes: priority_queue.Queue(#(List(Int), Int)),
//   get_neighbors: fn(List(Int)) -> List(List(Int)),
//   seen: dict.Dict(List(Int), Int),
// ) {
//   let node = nodes |> priority_queue.pop()
//   case node {
//     Error(_) -> seen
//     Ok(#(#(node, cost), nodes)) ->
//       case dict.get(seen, node) |> result.is_ok() {
//         True -> dijkstra(nodes, get_neighbors, seen)
//         False -> {
//           let seen = seen |> dict.insert(node, cost)
//
//           get_neighbors(node)
//           |> list.map(pair.new(_, cost + 1))
//           |> list.fold(nodes, priority_queue.push)
//           |> dijkstra(get_neighbors, seen)
//         }
//       }
//   }
// }
//
// pub fn task_2_line(input: #(List(Bool), List(List(Int)), List(Int))) {
//   let #(_, buttons, jolts) = input
//   let buttons = buttons |> list.map(button_press_2(_, jolts |> list.length))
//   let get_neighbors = get_neighbors(_, buttons, jolts)
//
//   let start =
//     jolts
//     |> list.map(fn(_) { 0 })
//
//   let queue =
//     priority_queue.new(fn(a: #(List(Int), Int), b: #(List(Int), Int)) {
//       int.compare(a.1, b.1)
//     })
//     |> priority_queue.push(#(start, 0))
//
//   dijkstra(queue, get_neighbors, dict.new())
//   |> dict.get(jolts)
//   |> result.unwrap(-1)
// }

pub type Message {
  Get(reply_to: process.Subject(Int))
  Push(value: Int)
  Shutdown
}

pub fn on_message(state: Int, message: Message) {
  case message {
    Get(reply_to:) -> {
      actor.send(reply_to, state)
      actor.continue(state)
    }
    Push(value:) -> {
      int.min(value, state)
      |> actor.continue()
    }
    Shutdown -> actor.stop()
  }
}

pub type Hilo {
  High
  Low
}

fn hilo_combine(a: Hilo, b: Hilo) {
  case a, b {
    High, _ -> High
    _, High -> High
    Low, Low -> Low
  }
}

fn to_hilo(int: Int) {
  case int {
    0 -> Low
    _ -> High
  }
}

pub fn get_possibilities(vecs: List(List(Int))) -> set.Set(List(Hilo)) {
  let possibilities = vecs |> list.map(list.map(_, to_hilo))
  list.range(0, vecs |> list.length)
  |> list.map(fn(take) {
    possibilities
    |> list.combinations(take)
    |> list.map(list.reduce(_, fn(a, b) { list.map2(a, b, hilo_combine) }))
    |> result.partition()
    |> pair.first()
  })
  |> list.flatten()
  |> set.from_list()
}

pub fn task_2_backtrack(
  cache,
  vecs: List(List(Int)),
  cost: Int,
  factor_max: Int,
  jolt: List(Int),
) {
  let min_cost = actor.call(cache, 20_000, Get)
  use <- bool.guard(when: cost > min_cost, return: Nil)

  // echo vecs |> list.length

  case vecs {
    [] -> Nil
    [head, ..tail] -> {
      let possibilities = get_possibilities(tail)
      list.range(0, factor_max)
      |> list.filter_map(fn(factor) {
        let cost = cost + factor
        use <- bool.guard(when: cost > min_cost, return: Error(Nil))

        let vec = head |> list.map(int.multiply(_, factor))
        let jolt = list.map2(jolt, vec, int.subtract)

        let all_zero = jolt |> list.all(fn(x) { x == 0 })
        use <- bool.lazy_guard(when: all_zero, return: fn() {
          actor.send(cache, Push(cost))
          Error(Nil)
        })

        let is_solution_feasible =
          jolt
          |> list.map(to_hilo)
          |> set.contains(possibilities, _)

        use <- bool.guard(when: !is_solution_feasible, return: Error(Nil))

        let one_below_zero = jolt |> list.any(fn(x) { x < 0 })
        use <- bool.guard(when: one_below_zero, return: Error(Nil))

        Ok(#(cost, jolt))
      })
      |> list.map(fn(x) {
        let #(cost, jolt) = x
        task_2_backtrack(cache, tail, cost, factor_max, jolt)
      })

      Nil
    }
  }
}

pub fn task_2_line(input: #(List(Bool), List(List(Int)), List(Int))) {
  let #(_, buttons, jolts) = input
  let vecs =
    buttons
    |> list.map(button_press_2(_, jolts |> list.length))
    |> list.sort(fn(a, b) { int.compare(list.length(a), list.length(b)) })
  let factor_max =
    jolts |> list.max(int.compare) |> result.unwrap(-1) |> int.add(1)
  let cost_upper_bound = vecs |> list.length |> int.multiply(factor_max)

  let assert Ok(actor) =
    actor.new(cost_upper_bound)
    |> actor.on_message(on_message)
    |> actor.start

  task_2_backtrack(actor.data, vecs, 0, factor_max, jolts)

  let min = actor.call(actor.data, 20_000, Get)

  actor.send(actor.data, Shutdown)
  min
}

pub fn task_2(input: List(#(List(Bool), List(List(Int)), List(Int)))) {
  let total = input |> list.length |> int.to_string
  input
  |> list.index_map(fn(line, i) { #(i, line) })
  |> palist.map(2, fn(line) {
    let #(i, line) = line
    task_2_line(line)
  })
  |> int.sum()
}

pub fn main() -> Nil {
  let assert Ok(input) = simplifile.read("input.txt")
  let input = input |> parse()

  io.print("Task 1: ")
  input |> task_1 |> int.to_string |> io.println
  io.print("Task 2: ")
  input |> task_2 |> int.to_string |> io.println
}
