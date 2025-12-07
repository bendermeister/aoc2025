import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import simplifile

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

pub fn task_1(input: String) {
  let subject = process.new_subject()
  input
  |> parse_input()
  |> list.map(fn(range) {
    process.spawn(fn() {
      list.range(range.0, range.1)
      |> list.filter(fn(x) {
        let parts = x |> int.to_string |> string.to_graphemes
        let #(a, b) = parts |> list.split(list.length(parts) / 2)
        a == b
      })
      |> int.sum()
      |> process.send(subject, _)
    })
  })
  |> list.map(fn(_) { process.receive_forever(subject) })
  |> int.sum()
}

pub fn task_2(input: String) {
  let subject = process.new_subject()

  input
  |> parse_input()
  |> list.map(fn(range) {
    process.spawn(fn() {
      list.range(range.0, range.1)
      |> list.filter(fn(number) {
        let number = number |> int.to_string()
        number
        |> string.to_graphemes()
        |> list.map_fold("", fn(acc, x) { #(acc <> x, acc <> x) })
        |> pair.second()
        |> list.filter(fn(x) { x != number })
        |> list.map(string.split(number, _))
        |> list.any(list.all(_, string.is_empty))
      })
      |> int.sum()
      |> process.send(subject, _)
    })
  })
  |> list.map(fn(_) { process.receive_forever(subject) })
  |> int.sum()
}

pub fn main() -> Nil {
  io.println("Hello from day_2!")

  let assert Ok(input) = simplifile.read("./input.txt")
  io.print("Task 1: ")
  input |> task_1() |> int.to_string() |> io.println()
  io.print("Task 2: ")
  input |> task_2() |> int.to_string() |> io.println()
}
