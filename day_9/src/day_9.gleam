import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import simplifile

pub fn rect_area(a: #(Int, Int), b: #(Int, Int)) {
  let width = { a.0 - b.0 |> int.absolute_value } + 1
  let height = { a.1 - b.1 |> int.absolute_value } + 1
  width * height
}

pub fn parse_input(input: String) {
  input
  |> string.trim()
  |> string.split("\n")
  |> list.map(string.trim)
  |> list.map(fn(line) {
    let assert Ok(#(x, y)) =
      line
      |> string.trim
      |> string.split_once(",")

    let assert Ok(x) = int.parse(x)
    let assert Ok(y) = int.parse(y)
    #(x, y)
  })
}

pub const input = "
7,1
11,1
11,7
9,7
9,5
2,5
2,3
7,3
"

fn is_rect_in_polygon(
  rect: #(#(Int, Int), #(Int, Int)),
  lines_vertical: List(#(#(Int, Int), #(Int, Int))),
  lines_horizontal: List(#(#(Int, Int), #(Int, Int))),
  lines_all: List(#(#(Int, Int), #(Int, Int))),
) {
  let #(a, b) = rect
  let rect_x_min = int.min(a.0, b.0)
  let rect_x_max = int.max(a.0, b.0)
  let rect_y_min = int.min(a.1, b.1)
  let rect_y_max = int.max(a.1, b.1)

  // check if any vertical lines are intersecting the rectangle
  let has_vertical_intersection =
    lines_vertical
    |> list.any(fn(line) {
      let line_x = line.0.0

      // line must be strictly in left and right bounds
      let in_bounds = rect_x_min < line_x && line_x < rect_x_max
      use <- bool.guard(when: !in_bounds, return: False)

      let line_start = int.min(line.0.1, line.1.1)
      let line_end = int.max(line.0.1, line.1.1)

      let is_above = line_end <= rect_y_min
      let is_below = line_start >= rect_y_max

      !is_above && !is_below
    })
  use <- bool.guard(when: has_vertical_intersection, return: False)

  // check if any horizontal lines are intersecting the rectangle
  let has_horizontal_intersection =
    lines_horizontal
    |> list.any(fn(line) {
      let line_y = line.0.1

      // line must be in upper lower rect bounds

      let in_bounds = rect_y_min < line_y && line_y < rect_y_max
      use <- bool.guard(when: !in_bounds, return: False)

      let line_start = int.min(line.0.0, line.1.0)
      let line_end = int.max(line.0.0, line.1.0)

      let is_left = line_end <= rect_x_min
      let is_right = line_start >= rect_x_max

      !is_left && !is_right
    })

  use <- bool.guard(when: has_horizontal_intersection, return: False)

  // check if all corners are inside the polygon with raycasting
  [
    #(rect_x_min, rect_y_min),
    #(rect_x_min, rect_y_max),
    #(rect_x_max, rect_y_max),
    #(rect_x_max, rect_y_min),
  ]
  // we don't need to check our original points
  |> list.filter(fn(point) { point != a && point != b })
  |> list.all(fn(point) {
    lines_all
    |> list.fold_until(False, fn(acc, line) {
      let line_x_max = int.max(line.0.0, line.1.0)
      let line_y_min = int.min(line.0.1, line.1.1)
      let line_y_max = int.max(line.0.1, line.1.1)

      let is_in_horizontal_bounds =
        line_y_min <= point.1 && point.1 <= line_y_max

      use <- bool.guard(
        when: !is_in_horizontal_bounds,
        return: list.Continue(acc),
      )

      case int.compare(line_x_max, point.0) {
        order.Lt -> list.Continue(!acc)
        order.Eq -> list.Stop(True)
        order.Gt -> list.Continue(acc)
      }
    })
  })
}

fn task_2(input: List(#(Int, Int))) {
  let assert Ok(last) = input |> list.last()

  let lines_all = [last, ..input] |> list.window_by_2()

  let #(lines_vertical, lines_horizontal) =
    lines_all
    |> list.partition(fn(pair) { pair.0.0 == pair.1.0 })

  input
  |> list.combination_pairs()
  |> list.fold(-1, fn(old_area, rect) {
    let area = rect_area(rect.0, rect.1)
    let is_area_smaller = area <= old_area
    use <- bool.guard(when: is_area_smaller, return: old_area)

    let is_rect_in_polygon =
      is_rect_in_polygon(rect, lines_vertical, lines_horizontal, lines_all)
    use <- bool.guard(when: !is_rect_in_polygon, return: old_area)

    area
  })
}

fn task_1(input: List(#(Int, Int))) {
  input
  |> list.combination_pairs()
  |> list.map(fn(pair) { rect_area(pair.0, pair.1) })
  |> list.max(int.compare)
  |> result.unwrap(0)
}

pub fn main() -> Nil {
  let assert Ok(input) = simplifile.read("input.txt")
  let input = input |> parse_input()
  io.print("Task 1: ")
  input |> task_1() |> int.to_string |> io.println
  io.print("Task 2: ")
  input |> task_2() |> int.to_string |> io.println
}
