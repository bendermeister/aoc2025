import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import gleamy/bench
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

pub type Hilo {
  High
  Low
}

fn hilo_combine(a: Hilo, b: Hilo) {
  case a, b {
    Low, Low -> Low
    _, _ -> High
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
  |> list.flat_map(fn(take) {
    possibilities
    |> list.combinations(take)
    |> list.map(list.reduce(_, fn(a, b) { list.map2(a, b, hilo_combine) }))
    |> result.partition()
    |> pair.first()
  })
  |> set.from_list()
}

pub fn task_2_backtrack(
  min_cost: Int,
  vecs: List(List(Int)),
  cost: Int,
  jolt: List(Int),
) -> Int {
  use <- bool.guard(when: cost > min_cost, return: min_cost)

  case vecs {
    [] -> min_cost
    [head, ..tail] -> {
      let possibilities = get_possibilities(tail)
      let factor_max =
        head
        |> list.zip(jolt)
        |> list.filter(fn(x) { x.0 != 0 })
        |> list.max(fn(a, b) { int.compare(a.1, b.1) |> order.negate })
        |> result.map(pair.second)
        |> result.unwrap(0)

      let #(solutions, subproblems) =
        list.range(0, factor_max)
        |> list.filter_map(fn(factor) {
          let cost = cost + factor
          use <- bool.guard(when: cost > min_cost, return: Error(Nil))

          let vec = head |> list.map(int.multiply(_, factor))
          let jolt = list.map2(jolt, vec, int.subtract)

          let all_zero = jolt |> list.all(fn(x) { x == 0 })
          let hilo = jolt |> list.map(to_hilo)

          use <- bool.lazy_guard(when: all_zero, return: fn() {
            Ok(#(True, cost, jolt))
          })

          let is_solution_feasible = set.contains(possibilities, hilo)

          use <- bool.guard(when: !is_solution_feasible, return: Error(Nil))

          Ok(#(False, cost, jolt))
        })
        |> list.partition(fn(x) { x.0 })

      let min_cost =
        solutions
        |> list.first()
        |> result.map(fn(x) { x.1 })
        |> result.unwrap(min_cost)

      subproblems
      |> list.fold(min_cost, fn(min_cost, x) {
        let #(_, cost, jolt) = x
        task_2_backtrack(min_cost, tail, cost, jolt)
      })
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

  task_2_backtrack(cost_upper_bound, vecs, 0, jolts)
}

pub fn task_2(input: List(#(List(Bool), List(List(Int)), List(Int)))) {
  input
  |> list.index_map(fn(x, i) { #(i, x) })
  |> palist.map(1, fn(x) {
    let r = task_2_line(x.1)
    // io.println(
    //   "Running line: " <> string.pad_start(int.to_string(x.0), with: "0", to: 4),
    // )
    r
  })
  |> int.sum()
}

pub const input = [
  #(
    [False, True, True, False],
    [[3], [1, 3], [2], [2, 3], [0, 2], [0, 1]],
    [3, 5, 4, 7],
  ),
  #(
    [False, False, False, True, False],
    [[0, 2, 3, 4], [2, 3], [0, 4], [0, 1, 2], [1, 2, 3, 4]],
    [7, 5, 12, 7, 2],
  ),
  #(
    [False, True, True, True, False, True],
    [[0, 1, 2, 3, 4], [0, 3, 4], [0, 1, 2, 4, 5], [1, 2]],
    [10, 11, 11, 5, 10, 5],
  ),
]

pub fn main() -> Nil {
  // let assert Ok(input) = simplifile.read("input.txt")
  // let input = input |> parse()
  // io.print("Task 1: ")
  // input |> task_1 |> int.to_string |> io.println
  // io.print("Task 2: ")
  // input |> task_2 |> int.to_string |> io.println

  bench.run(
    [bench.Input("data", input)],
    [
      // bench.Function("task_1", task_1),
      bench.Function("task_2", task_2),
    ],
    [
      bench.Duration(10_000),
      bench.Warmup(10),
    ],
  )
  |> bench.table([
    bench.Mean,
    bench.SD,
    bench.P(99),
  ])
  |> io.println
}
