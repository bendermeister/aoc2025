import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/pair
import gleam/result
import gleam/string
import simplifile

pub fn task_1(input: String) -> Int {
  input
  |> string.trim()
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.map(string.to_graphemes)
  |> list.map(fn(bank) {
    bank
    |> list.map(int.parse)
    |> result.partition
    |> pair.first
    |> list.reverse
  })
  |> list.map(fn(bank) {
    let top = bank |> list.take(list.length(bank) - 1)
    let #(index, top) =
      top
      |> list.index_fold(#(-1, 0), fn(acc, battery, index) {
        case int.compare(acc.1, battery) {
          order.Lt -> #(index, battery)
          order.Eq -> acc
          order.Gt -> acc
        }
      })
    let lower = bank |> list.drop(index + 1)
    let lower = lower |> list.max(int.compare) |> result.unwrap(0)
    top * 10 + lower
  })
  |> int.sum()
}

pub fn task_2(input: String) -> Int {
  input
  |> string.trim()
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.map(string.to_graphemes)
  |> list.map(fn(x) {
    x
    |> list.map(int.parse)
    |> result.partition()
    |> pair.first()
    |> list.reverse()
  })
  |> list.map(fn(bank) {
    let bank_length = list.length(bank)
    list.range(0, 11)
    |> list.reverse()
    |> list.map(fn(x) { bank |> list.take(bank_length - x) })
    |> list.fold(#(0, []), fn(acc, bank) {
      let #(drop, acc) = acc
      let #(index, next) =
        bank
        |> list.drop(drop)
        |> list.index_fold(#(-1, 0), fn(acc, battery, index) {
          case int.compare(acc.1, battery) {
            order.Lt -> #(index, battery)
            _ -> acc
          }
        })
      #(drop + index + 1, [next, ..acc])
    })
    |> pair.second()
    |> list.reverse()
    |> list.map(int.to_string)
    |> string.join("")
  })
  |> list.map(int.parse)
  |> result.partition()
  |> pair.first()
  |> list.reverse()
  |> int.sum()
}

pub fn main() -> Nil {
  // let input =
  //   "987654321111111
  // 811111111111119
  // 234234234234278
  // 818181911112111
  // "
  let assert Ok(input) = simplifile.read("./input.txt")
  io.print("Task 1: ")
  input |> task_1 |> int.to_string |> io.println
  io.print("Task 2: ")
  input |> task_2 |> int.to_string |> io.println
}
