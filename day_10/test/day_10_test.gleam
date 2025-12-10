import day_10.{High, Low}
import gleam/list
import gleam/set
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

const input_str = "
[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}
[...#.] (0,2,3,4) (2,3) (0,4) (0,1,2) (1,2,3,4) {7,5,12,7,2}
[.###.#] (0,1,2,3,4) (0,3,4) (0,1,2,4,5) (1,2) {10,11,11,5,10,5}
"

const input = [
  #(
    [False, True, True, False],
    [[3], [1, 3], [2], [2, 3], [0, 2], [0, 1]],
    [3, 5, 4, 7],
  ),
  #(
    [False, False, False, True, False],
    [[0, 2, 3, 4], [2, 3], [0, 4], [0, 1, 2], [1, 2, 3, 4]],
    [7, 5, 12, 7, 2],
  ),
  #(
    [False, True, True, True, False, True],
    [[0, 1, 2, 3, 4], [0, 3, 4], [0, 1, 2, 4, 5], [1, 2]],
    [10, 11, 11, 5, 10, 5],
  ),
]

pub fn parse_line_test() {
  let line = "[.##.] (3) (1,3) (2) (2,3) (0,2) (0,1) {3,5,4,7}"
  let output = day_10.parse_line(line)
  let expected = #(
    [False, True, True, False],
    [[3], [1, 3], [2], [2, 3], [0, 2], [0, 1]],
    [3, 5, 4, 7],
  )
  assert output == expected
}

pub fn button_press_test() {
  let output = [[3], [1, 3], [2]] |> day_10.button_press(4)
  let lights = [False, True, True, False]
  assert output == lights
}

pub fn task_1_test() {
  assert day_10.task_1(input) == 7
}

pub fn parse_test() {
  let output = day_10.parse(input_str)
  assert output == input
}

pub fn task_2_line_test() {
  let assert Ok(input) = input |> list.first()
  assert day_10.task_2_line(input) == 10
}

pub fn task_2_line_2_test() {
  let assert Ok(input) = input |> list.drop(1) |> list.first()
  assert day_10.task_2_line(input) == 12
}

pub fn task_2_line_3_test() {
  let assert Ok(input) = input |> list.drop(2) |> list.first()
  assert day_10.task_2_line(input) == 11
}

pub fn task_2_test() {
  assert day_10.task_2(input) == 33
}

pub fn task_2_get_possibilities_test() {
  let vecs = [[0, 0, 1, 1], [1, 1, 0, 0]]
  let output = day_10.get_possibilities(vecs)

  assert set.contains(output, [Low, Low, High, High])
  assert set.contains(output, [High, High, Low, Low])
  assert set.contains(output, [High, High, High, High])
  assert set.size(output) == 3
}
