import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/otp/actor
import gleam/string
import simplifile
import util/memo

pub type Node {
  Node(String)
}

pub fn parse_input(input: String) -> dict.Dict(Node, List(Node)) {
  input
  |> string.trim()
  |> string.split("\n")
  |> list.map(fn(line) {
    let assert Ok(#(node, neighbors)) = line |> string.split_once(":")
    let node = node |> string.trim() |> Node

    let neighbors =
      neighbors
      |> string.split(" ")
      |> list.map(string.trim)
      |> list.filter(fn(x) { !string.is_empty(x) })
      |> list.map(Node)

    #(node, neighbors)
  })
  |> dict.from_list()
}

pub fn dfs(
  cache,
  graph: dict.Dict(Node, List(Node)),
  node: Node,
  target: Node,
) -> Int {
  use <- memo.memoize(cache, node)
  use <- bool.guard(when: node == target, return: 1)
  let assert Ok(neighbors) = dict.get(graph, node)
  neighbors
  |> list.map(dfs(cache, graph, _, target))
  |> int.sum()
}

pub fn dfs_wrapper(
  graph: dict.Dict(Node, List(Node)),
  start: Node,
  target: Node,
  forbidden: List(Node),
) {
  use cache <- memo.new()

  forbidden
  |> list.map(fn(forbidden) { actor.send(cache, memo.Push(forbidden, 0)) })

  dfs(cache, graph, start, target)
}

pub fn task_1(input: dict.Dict(Node, List(Node))) {
  use cache <- memo.new()
  dfs(cache, input, Node("you"), Node("out"))
}

pub fn task_2(graph: dict.Dict(Node, List(Node))) -> Int {
  let svr = Node("svr")
  let fft = Node("fft")
  let dac = Node("dac")
  let out = Node("out")

  let svr_to_fft = dfs_wrapper(graph, svr, fft, [out, dac])
  let svr_to_dac = dfs_wrapper(graph, svr, dac, [fft, out])

  let fft_to_dac = dfs_wrapper(graph, fft, dac, [svr, out])

  let dac_to_fft = dfs_wrapper(graph, dac, fft, [svr, out])

  let fft_to_out = dfs_wrapper(graph, fft, out, [dac, svr])
  let dac_to_out = dfs_wrapper(graph, dac, out, [svr, fft])

  let one = svr_to_fft * fft_to_dac * dac_to_out
  let two = svr_to_dac * dac_to_fft * fft_to_out

  one + two
}

pub fn main() -> Nil {
  let assert Ok(input) = simplifile.read("input.txt")
  let input = input |> parse_input()

  io.print("Task 1: ")
  input |> task_1 |> int.to_string |> io.println()
  io.print("Task 2: ")
  input |> task_2 |> int.to_string |> io.println()
}
