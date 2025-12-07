import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import simplifile

pub fn task_1(input: String) -> Int {
  let map =
    input
    |> string.trim()
    |> string.split("\n")
    |> list.map(string.trim)
    |> list.map(string.to_graphemes)
    |> list.map(
      list.map(_, fn(x) {
        case x {
          "@" -> 1
          _ -> 0
        }
      }),
    )
    |> list.index_map(fn(line, y) {
      line
      |> list.index_map(fn(part, x) { #(#(x, y), part) })
    })
    |> list.flatten()

  let lookup = map |> dict.from_list

  map
  |> list.filter(fn(x) { x.1 == 1 })
  |> list.map(pair.first)
  |> list.map(fn(x) {
    adjacent_points
    |> list.map(fn(y) { #(x.0 + y.0, x.1 + y.1) })
    |> list.map(dict.get(lookup, _))
    |> list.map(result.unwrap(_, 0))
    |> int.sum()
  })
  |> list.filter(fn(x) { x < 4 })
  |> list.length()
}

const adjacent_points = [
  #(-1, -1),
  #(0, -1),
  #(1, -1),
  #(-1, 0),
  #(1, 0),
  #(-1, 1),
  #(0, 1),
  #(1, 1),
]

pub fn update_rolls(rolls: set.Set(#(Int, Int))) -> set.Set(#(Int, Int)) {
  let update =
    rolls
    |> set.to_list()
    |> list.filter(fn(x) {
      let count =
        adjacent_points
        |> list.map(fn(y) { #(x.0 + y.0, x.1 + y.1) })
        |> list.map(set.contains(rolls, _))
        |> list.count(fn(x) { x })
      count >= 4
    })
    |> set.from_list()

  set.difference(rolls, update)
  |> set.size()
  |> fn(x) {
    case x {
      0 -> rolls
      _ -> update_rolls(update)
    }
  }
}

pub fn task_2(input: String) {
  let rolls =
    input
    |> string.trim()
    |> string.split("\n")
    |> list.map(string.trim)
    |> list.map(string.to_graphemes)
    |> list.map(
      list.map(_, fn(x) {
        case x {
          "@" -> 1
          _ -> 0
        }
      }),
    )
    |> list.index_map(fn(line, y) {
      line |> list.index_map(fn(part, x) { #(#(x, y), part) })
    })
    |> list.flatten()
    |> list.filter(fn(x) { x.1 == 1 })
    |> list.map(pair.first)
    |> set.from_list()

  let update = update_rolls(rolls)

  let rolls = rolls |> set.size()
  let update = update |> set.size()

  rolls - update
}

pub fn main() -> Nil {
  //   let input =
  //     "
  // ..@@.@@@@.
  // @@@.@.@.@@
  // @@@@@.@.@@
  // @.@@@@..@.
  // @@.@@@@.@@
  // .@@@@@@@.@
  // .@.@.@.@@@
  // @.@@@.@@@@
  // .@@@@@@@@.
  // @.@.@@@.@.
  //     "

  let assert Ok(input) = simplifile.read("./input.txt")

  io.print("Task 1: ")
  input |> task_1 |> int.to_string |> io.println

  io.print("Task 2: ")
  input |> task_2 |> int.to_string |> io.println
}
