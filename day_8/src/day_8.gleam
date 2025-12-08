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
import gleam/yielder
import gleamy/bench
import simplifile
import util/union_find

pub fn parse_input(input: String) {
  input
  |> string.trim()
  |> string.split("\n")
  |> list.map(fn(x) {
    let assert [Ok(a), Ok(b), Ok(c)] =
      x
      |> string.split(",")
      |> list.map(string.trim)
      |> list.map(int.parse)
    #(a, b, c)
  })
}

pub const input = "
162,817,812
57,618,57
906,360,560
592,479,940
352,342,300
466,668,158
542,29,236
431,825,988
739,650,466
52,470,668
216,146,977
819,987,18
117,168,530
805,96,715
346,949,466
970,615,88
941,993,340
862,61,35
984,92,344
425,690,689
"

pub fn main() -> Nil {
  let assert Ok(input) = simplifile.read("input.txt")

  let input = input |> parse_input
  io.print("Task 1: ")
  input |> task_1() |> int.to_string |> io.println
  io.print("Task 1_: ")
  input |> task_1_() |> int.to_string |> io.println
  io.print("Task 1__: ")
  input |> task_1__() |> int.to_string |> io.println
  io.print("Task 1___: ")
  input |> task_1___() |> int.to_string |> io.println
  io.print("Task 2: ")
  input |> task_2() |> int.to_string |> io.println

  bench.run(
    [bench.Input("data", input)],
    [
      bench.Function("task_1", task_1),
      bench.Function("task_1_", task_1_),
      bench.Function("task_1__", task_1__),
      bench.Function("task_1___", task_1___),
      bench.Function("task_2", task_2),
    ],
    [
      bench.Duration(10_000),
      bench.Warmup(10),
    ],
  )
  |> bench.table([
    bench.IPS,
    bench.Mean,
    bench.SD,
    bench.P(99),
  ])
  |> io.println
}

pub fn distance(a: #(Int, Int, Int), b: #(Int, Int, Int)) {
  let x = a.0 - b.0
  let y = a.1 - b.1
  let z = a.2 - b.2
  x * x + y * y + z * z
}

pub fn to_sorted_tuples(list: List(#(Int, Int, Int))) {
  list
  |> list.combination_pairs()
  |> list.map(fn(pair) { #(distance(pair.0, pair.1), pair) })
  |> list.sort(fn(a, b) { int.compare(a.0, b.0) })
  |> list.map(pair.second)
}

pub fn task_1___(input: List(#(Int, Int, Int))) {
  let uf =
    input
    |> to_sorted_tuples()
    |> list.take(1000)
    |> list.fold(union_find.new(), fn(uf, pair) {
      uf |> union_find.union_sets(pair.0, pair.1)
    })

  input
  |> list.group(fn(v) {
    union_find.find_set(uf, v)
    |> result.map(pair.second)
  })
  |> dict.delete(Error(Nil))
  |> dict.to_list()
  |> list.map(pair.second)
  |> list.map(list.length)
  |> list.sort(order.reverse(int.compare))
  |> list.take(3)
  |> int.product()
}

pub fn task_1_(input: List(#(Int, Int, Int))) {
  let uf =
    input
    |> to_sorted_tuples()
    |> list.take(1000)
    |> list.fold(union_find.new(), fn(uf, pair) {
      uf |> union_find.union_sets(pair.0, pair.1)
    })

  input
  |> list.fold(#(uf, dict.new()), fn(acc, v) {
    let #(uf, groups) = acc
    let parent = union_find.find_set(uf, v)
    case parent {
      Error(_) -> #(uf, groups)
      Ok(#(uf, parent)) ->
        groups
        |> dict.get(parent)
        |> result.unwrap([])
        |> fn(tail) { [v, ..tail] }
        |> dict.insert(groups, parent, _)
        |> pair.new(uf, _)
    }
  })
  |> pair.second()
  |> dict.to_list()
  |> list.map(pair.second)
  |> list.map(list.length)
  |> list.sort(order.reverse(int.compare))
  |> list.take(3)
  |> int.product()
}

pub fn task_1__(input: List(#(Int, Int, Int))) {
  input
  |> to_sorted_tuples()
  |> yielder.from_list()
  |> yielder.take(1000)
  |> yielder.fold(dict.new(), fn(graph, pair) {
    let #(a, b) = pair
    let a_value = graph |> dict.get(a) |> result.lazy_unwrap(fn() { [a] })
    let b_value = graph |> dict.get(b) |> result.lazy_unwrap(fn() { [b] })

    let value = list.append(a_value, b_value) |> list.unique()

    value
    |> list.fold(graph, fn(graph, key) { graph |> dict.insert(key, value) })
  })
  |> dict.to_list()
  |> list.map(pair.second)
  |> list.group(fn(a) {
    a
    |> list.max(fn(a, b) {
      int.compare(a.0, b.0)
      |> order.break_tie(int.compare(a.1, b.1))
      |> order.break_tie(int.compare(a.2, b.2))
    })
  })
  |> dict.to_list()
  |> list.map(pair.second)
  |> list.map(list.length)
  |> list.sort(order.reverse(int.compare))
  |> list.take(3)
  |> int.product()
}

pub fn task_1(input: List(#(Int, Int, Int))) {
  input
  |> to_sorted_tuples()
  |> yielder.from_list()
  |> yielder.take(1000)
  |> yielder.fold(dict.new(), fn(graph, pair) {
    let #(a, b) = pair
    let a_value = graph |> dict.get(a) |> result.lazy_unwrap(fn() { [a] })
    let b_value = graph |> dict.get(b) |> result.lazy_unwrap(fn() { [b] })

    let value = list.append(a_value, b_value) |> list.unique()

    value
    |> list.fold(graph, fn(graph, key) { graph |> dict.insert(key, value) })
  })
  |> dict.to_list()
  |> list.map(pair.second)
  |> list.map(
    list.sort(_, fn(a, b) {
      int.compare(a.0, b.0)
      |> order.break_tie(int.compare(a.1, b.1))
      |> order.break_tie(int.compare(a.2, b.2))
    }),
  )
  |> list.unique()
  |> list.map(list.length)
  |> list.sort(order.reverse(int.compare))
  |> list.take(3)
  |> int.product()
}

pub fn task_2(input: List(#(Int, Int, Int))) {
  let input_length = input |> list.length()
  input
  |> to_sorted_tuples()
  |> list.fold_until(#(set.new(), []), fn(acc, head) {
    let #(set, list) = acc
    use <- bool.guard(
      when: set.size(set) == input_length,
      return: list.Stop(acc),
    )
    let #(a, b) = head
    let a_known = set.contains(set, a)
    let b_known = set.contains(set, b)
    let known = a_known && b_known
    let set = set |> set.insert(a) |> set.insert(b)

    let list = case known {
      False -> [head, ..list]
      True -> list
    }
    #(set, list) |> list.Continue
  })
  |> pair.second
  |> list.first()
  |> result.unwrap(#(#(0, 0, 0), #(0, 0, 0)))
  |> fn(pair) { pair.0.0 * pair.1.0 }
}
