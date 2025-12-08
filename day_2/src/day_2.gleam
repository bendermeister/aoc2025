import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import simplifile
import util/palist

pub fn get_tenner(input: Int) {
  get_tenner_(input, 10, 1)
}

pub fn get_tenner_(input, tenner, acc) {
  use <- bool.guard(when: input < tenner, return: acc)
  get_tenner_(input, tenner * 10, acc + 1)
}

pub fn exp10(exp: Int) {
  list.repeat(10, exp)
  |> int.product()
}

pub fn parse_input(input: String) -> List(#(Int, Int)) {
  input
  |> string.split(",")
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
  |> list.filter(fn(x) {
    let #(start, end) = x
    let start = get_tenner(start) % 2 == 0
    let end = get_tenner(end) % 2 == 0
    start || end
  })
  |> palist.map(1, fn(range) {
    list.range(range.0, range.1)
    |> list.filter(fn(input) {
      let exponent = get_tenner(input) / 2
      let stub = exp10(exponent)
      let part = input % stub
      let parts = part * stub + part
      parts == input
    })
    |> int.sum()
  })
  |> int.sum()
}

pub fn task_2_lookup(input_length: Int, part_length: Int) {
  case input_length, part_length {
    2, 1 -> 11
    3, 1 -> 111
    4, 1 -> 1111
    4, 2 -> 0101
    5, 1 -> 11_111
    6, 1 -> 111_111
    6, 2 -> 010_101
    6, 3 -> 001_001
    7, 1 -> 1_111_111
    8, 1 -> 11_111_111
    8, 2 -> 01_010_101
    8, 4 -> 00_010_001
    9, 1 -> 111_111_111
    9, 3 -> 001_001_001
    10, 1 -> 1_111_111_111
    10, 2 -> 0_101_010_101
    10, 5 -> 0_000_100_001
    a, _ if a <= 10 -> 0
    _, _ -> panic
  }
}

pub fn task_2(input: List(#(Int, Int))) {
  input
  |> palist.map(1, fn(range) {
    list.range(range.0, range.1)
    |> list.filter(fn(input) {
      let exp = get_tenner(input)
      list.range(1, exp - 1)
      |> list.filter(fn(x) { exp % x == 0 })
      |> list.any(fn(x) {
        let part = input % exp10(x)
        let factor = task_2_lookup(exp, x)
        factor * part == input
      })
    })
    |> int.sum()
  })
  |> int.sum()
}

pub const input = "
11-22,95-115,998-1012,1188511880-1188511890,222220-222224,
1698522-1698528,446443-446449,38593856-38593862,565653-565659,
824824821-824824827,2121212118-2121212124
"

pub fn main() -> Nil {
  let assert Ok(input) = simplifile.read("./input.txt")

  let input = input |> parse_input

  io.print("Task 1: ")
  input |> task_1() |> int.to_string() |> io.println()
  io.print("Task 2: ")
  input |> task_2() |> int.to_string() |> io.println()
}
