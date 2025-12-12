import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile

pub type Grid {
  Grid(width: Int, height: Int, values: List(Int))
}

pub fn input_parse(input: String) {
  let assert Ok(grids) =
    input
    |> string.trim()
    |> string.split("\n\n")
    |> list.last()

  grids
  |> string.split("\n")
  |> list.map(fn(grid) {
    let grid = grid |> string.trim()
    let assert Ok(#(dimension, values)) = grid |> string.split_once(":")
    let assert Ok(#(width, height)) = dimension |> string.split_once("x")
    let values =
      values
      |> string.trim()
      |> string.split(" ")
      |> list.map(int.parse)
      |> list.map(fn(x) {
        let assert Ok(x) = x
        x
      })

    let assert Ok(width) = width |> int.parse()
    let assert Ok(height) = height |> int.parse()

    Grid(width:, height:, values:)
  })
}

pub fn task_1(input: List(Grid)) -> Int {
  input
  |> list.count(fn(grid) {
    let values = grid.values |> list.map(int.multiply(_, 8)) |> int.sum()
    let area = grid.width * grid.height
    values < area
  })
}

pub fn main() {
  let assert Ok(input) = simplifile.read("input.txt")
  io.print("Task 1: ")
  input |> input_parse() |> task_1 |> int.to_string |> io.println()
}
