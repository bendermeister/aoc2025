import gleam/int
import gleam/list
import gleam/result
import util/point

pub type Field(a) {
  Field(width: Int, height: Int, points: List(#(point.Point, a)))
}

pub fn from_list(list: List(List(a))) -> Field(a) {
  let height = list |> list.length()
  let width =
    list |> list.map(list.length) |> list.max(int.compare) |> result.unwrap(0)
  let points =
    list
    |> list.index_map(fn(line, y) {
      line
      |> list.index_map(fn(p, x) { #(point.new(x, y), p) })
    })
    |> list.flatten()
  Field(height:, width:, points:)
}

pub fn width(field: Field(a)) {
  field.width
}

pub fn height(field: Field(a)) {
  field.height
}

pub fn points(field: Field(a)) {
  field.points
}
