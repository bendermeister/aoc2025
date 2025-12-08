import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import simplifile
import util/palist

pub fn parse_input(input: String) -> List(#(Int, Int)) {
  input
  |> string.trim()
  |> string.split(",")
  |> list.map(string.trim)
  |> list.map(string.split_once(_, "-"))
  |> result.partition()
  |> pair.first()
  |> list.map(fn(x) {
    let start = x |> pair.first |> int.parse()
    use start <- result.try(start)
    let end = x |> pair.second |> int.parse()
    use end <- result.try(end)
    #(start, end)
    |> Ok
  })
  |> result.partition()
  |> pair.first()
}

pub fn task_1(input: List(#(Int, Int))) {
  input
  |> palist.map(1, fn(range) {
    list.range(range.0, range.1)
    |> list.filter(repeats2)
    |> int.sum()
  })
  |> int.sum()
}

pub fn task_2(input: List(#(Int, Int))) {
  input
  |> palist.map(1, fn(range) {
    list.range(range.0, range.1)
    |> list.filter(repeats)
  })
  |> list.flatten()
  |> int.sum()
}

pub fn repeater(acc: Int, ceiling: Int, tenner: Int, part: Int) {
  use <- bool.guard(when: acc >= ceiling, return: acc)
  acc * tenner + part
  |> repeater(ceiling, tenner, part)
}

pub fn tenner(input: Int) {
  tenner_(input, 10)
}

pub fn tenner_(input: Int, current: Int) -> List(Int) {
  use <- bool.guard(when: input < current, return: [])
  [current, ..tenner_(input, current * 10)]
}

pub fn repeats2(input: Int) -> Bool {
  tenner(input)
  |> list.any(fn(tenner) {
    let part = input % tenner
    use <- bool.guard(when: part == 0, return: False)
    let parts = part * tenner + part

    case parts == input {
      False -> False
      True ->
        input
        |> int.to_string()
        |> string.split(part |> int.to_string)
        |> list.all(string.is_empty)
    }
  })
}

pub fn repeats(input: Int) -> Bool {
  tenner(input)
  |> list.any(fn(tenner) {
    let part = input % tenner
    use <- bool.guard(when: part == 0, return: False)
    let parts = repeater(0, input, tenner, part)

    case parts == input {
      False -> False
      True ->
        input
        |> int.to_string()
        |> string.split(part |> int.to_string)
        |> list.all(string.is_empty)
    }
  })
}

pub fn main() -> Nil {
  io.println("Hello from day_2!")

  let assert Ok(input) = simplifile.read("./input.txt")

  let input = input |> parse_input

  io.print("Task 1: ")
  input |> task_1() |> int.to_string() |> io.println()
  io.print("Task 2: ")
  input |> task_2() |> int.to_string() |> io.println()
}
