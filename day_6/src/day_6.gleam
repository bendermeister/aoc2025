import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import simplifile

pub fn task_1(input: String) {
  input
  |> string.trim()
  |> string.replace("\t", " ")
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.map(fn(x) {
    x |> string.split(" ") |> list.filter(fn(x) { !string.is_empty(x) })
  })
  |> list.transpose()
  |> list.map(list.reverse)
  |> list.map(fn(list) {
    let assert [op, ..list] = list
    let op = case op {
      "+" -> int.add
      "*" -> int.multiply
      _ -> panic
    }
    list
    |> list.map(int.parse)
    |> result.partition
    |> pair.first
    |> list.reduce(op)
    |> result.unwrap(0)
  })
  |> int.sum()
}

pub fn task_2(input: String) {
  let input =
    input |> string.replace("\t", " ") |> string.trim() |> string.split("\n")
  let assert Ok(separator) = input |> list.last
  let separator =
    separator
    |> string.to_graphemes()
    |> list.index_map(fn(x, index) {
      case x {
        " " -> Error(Nil)
        _ -> Ok(index)
      }
    })
    |> result.partition
    |> pair.first
    |> list.map(int.subtract(_, 1))

  input
  |> list.map(string.to_graphemes)
  |> list.map(
    list.index_map(_, fn(x, index) {
      case list.contains(separator, index) {
        False -> x
        True -> "|"
      }
    }),
  )
  |> list.map(string.join(_, ""))
  |> list.map(string.split(_, "|"))
  |> list.transpose()
  |> list.map(list.reverse)
  |> list.map(fn(x) {
    let assert [op, ..numbers] = x

    let #(op, base) = case op |> string.trim() {
      "*" -> #(int.multiply, 1)
      "+" -> #(int.add, 0)
      _ -> panic
    }

    numbers
    |> list.reverse()
    |> list.map(string.to_graphemes)
    |> list.transpose
    |> list.map(string.join(_, ""))
    |> list.map(string.trim)
    |> list.map(int.parse)
    |> result.partition
    |> pair.first
    |> list.reverse
    |> list.fold(base, op)
  })
  |> int.sum()
}

pub fn main() -> Nil {
  let input =
    "
123 328  51 64 
 45 64  387 23 
  6 98  215 314
*   +   *   +
    "
  let assert Ok(input) = simplifile.read("input.txt")
  io.print("Task 1: ")
  input |> task_1 |> int.to_string |> io.println
  io.print("Task 2: ")
  input |> task_2 |> int.to_string |> io.println
}
