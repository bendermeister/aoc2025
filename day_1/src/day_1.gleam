import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import simplifile

pub type Rotation {
  Left(Int)
  Right(Int)
}

pub fn rotation_parse(rotation: String) -> Result(Rotation, Nil) {
  case rotation {
    "L" <> num -> num |> int.parse() |> result.map(Left)
    "R" <> num -> num |> int.parse() |> result.map(Right)
    _ -> Error(Nil)
  }
}

pub fn input_parse(string: String) -> List(Rotation) {
  string
  |> string.trim()
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.map(rotation_parse)
  |> result.partition()
  |> pair.first()
  |> list.reverse()
}

pub fn task_1(input: List(Rotation)) -> Int {
  input
  |> list.map_fold(50, fn(acc, rotation) {
    case rotation {
      Left(num) -> acc - num
      Right(num) -> acc + num
    }
    |> fn(x) { x % 100 }
    |> fn(x) { #(x, x) }
  })
  |> pair.second()
  |> list.count(fn(x) { x == 0 })
}

pub fn task_2(input: List(Rotation)) -> Int {
  input
  |> list.flat_map(fn(x) {
    case x {
      Left(x) -> list.repeat(Left(1), x)
      Right(x) -> list.repeat(Right(1), x)
    }
  })
  |> task_1()
}

pub fn main() -> Nil {
  let assert Ok(input) = simplifile.read("./input.txt")
  let input =
    input
    |> input_parse()

  io.print("Task 1: ")
  input |> task_1 |> int.to_string() |> io.println()

  io.print("Task 2: ")
  input |> task_2 |> int.to_string() |> io.println()
}
