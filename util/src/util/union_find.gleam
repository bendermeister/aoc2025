import gleam/bool
import gleam/dict
import gleam/pair
import gleam/result

pub opaque type UnionFind(a) {
  UnionFind(parent: dict.Dict(a, a), size: dict.Dict(a, Int))
}

pub fn new() {
  UnionFind(parent: dict.new(), size: dict.new())
}

pub fn find_set(uf: UnionFind(a), v: a) -> Result(#(UnionFind(a), a), Nil) {
  let parent = uf.parent |> dict.get(v)
  use parent <- result.try(parent)
  case parent == v {
    False -> {
      let parent = find_set(uf, parent)
      use #(uf, parent) <- result.try(parent)
      uf.parent
      |> dict.insert(v, parent)
      |> UnionFind(uf.size)
      |> pair.new(parent)
      |> Ok
    }
    True -> #(uf, v) |> Ok
  }
}

pub fn find_or_add(uf: UnionFind(a), v0: a) -> #(UnionFind(a), a) {
  uf
  |> find_set(v0)
  |> result.lazy_unwrap(fn() {
    uf.parent
    |> dict.insert(v0, v0)
    |> UnionFind(uf.size |> dict.insert(v0, 1))
    |> pair.new(v0)
  })
}

pub fn add(uf: UnionFind(a), v: a) -> UnionFind(a) {
  find_or_add(uf, v)
  |> pair.first
}

pub fn union_sets(uf: UnionFind(a), v0: a, v1: a) {
  let #(uf, v0) = find_or_add(uf, v0)
  let #(uf, v1) = find_or_add(uf, v1)
  use <- bool.guard(when: v0 == v1, return: uf)

  let size_v0 = uf.size |> dict.get(v0) |> result.unwrap(0)
  let size_v1 = uf.size |> dict.get(v1) |> result.unwrap(0)
  let size = size_v0 + size_v1

  case size_v0 < size_v1 {
    True -> {
      uf.parent
      |> dict.insert(v0, v1)
      |> UnionFind(uf.size |> dict.insert(v1, size))
    }
    False -> {
      uf.parent
      |> dict.insert(v1, v0)
      |> UnionFind(uf.size |> dict.insert(v0, size))
    }
  }
}
