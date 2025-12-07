import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/pair
import gleam/result
import gleam/string
import simplifile

fn occurs(valid: List(#(Int, Int)), id: Int) {
  case valid {
    [#(start, end), ..tail] -> {
      case int.compare(start, id), int.compare(id, end) {
        order.Gt, _ -> occurs(tail, id)
        _, order.Gt -> occurs(tail, id)
        _, _ -> True
      }
    }
    [] -> False
  }
}

pub fn task_1(input: String) {
  let assert [valid, ids] = input |> string.trim |> string.split("\n\n")

  let valid =
    valid
    |> string.trim()
    |> string.split("\n")
    |> list.map(string.trim)
    |> list.map(string.split_once(_, "-"))
    |> result.partition()
    |> pair.first()
    |> list.map(fn(x) {
      let start = x |> pair.first |> int.parse
      use start <- result.try(start)
      let end = x |> pair.second |> int.parse
      use end <- result.try(end)
      #(start, end)
      |> Ok
    })
    |> result.partition
    |> pair.first

  ids
  |> string.trim()
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.map(int.parse)
  |> result.partition
  |> pair.first
  |> list.count(occurs(valid, _))
}

pub fn task_2(input: String) -> Int {
  let assert [valid, _] = input |> string.trim() |> string.split("\n\n")

  valid
  |> string.trim()
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.map(string.split_once(_, "-"))
  |> result.partition()
  |> pair.first()
  |> list.map(fn(x) {
    let start = x |> pair.first |> int.parse
    use start <- result.try(start)
    let end = x |> pair.second |> int.parse
    use end <- result.try(end)
    #(start, end)
    |> Ok
  })
  |> result.partition
  |> pair.first
  |> list.sort(fn(a, b) {
    int.compare(a.0, b.0)
    |> order.lazy_break_tie(fn() { int.compare(a.1, b.1) })
  })
  |> list.fold([], fn(acc, b) {
    case acc {
      [] -> [b]
      [a, ..tail] -> {
        let #(a_start, a_end) = a
        let #(b_start, b_end) = b
        let ordering =
          [a_start, a_end, b_start, b_end] |> list.sort(int.compare)

        let matches =
          [
            [a_start, b_start, b_end, a_end],
            [b_start, a_start, a_end, b_end],
            [a_start, b_start, a_end, b_end],
            [b_start, a_start, b_end, a_end],
          ]
          |> list.any(fn(x) { x == ordering })

        case matches {
          False -> [b, a, ..tail]
          True -> {
            let start = int.min(a_start, b_start)
            let end = int.max(a_end, b_end)
            [#(start, end), ..tail]
          }
        }
      }
    }
  })
  |> list.map(fn(x) { x.1 - x.0 + 1 })
  |> int.sum()
}

pub fn main() -> Nil {
  //   let input =
  //     "
  // 3-5
  // 10-14
  // 16-20
  // 12-18
  //
  // 1
  // 5
  // 8
  // 11
  // 17
  // 32
  // "

  let assert Ok(input) = simplifile.read("input.txt")

  io.print("Task 1: ")
  input |> task_1() |> int.to_string() |> io.println
  io.print("Task 2: ")
  input |> task_2() |> int.to_string() |> io.println
}
