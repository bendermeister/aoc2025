import day_12
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

const input = "
0:
###
##.
##.

1:
###
##.
.##

2:
.##
###
##.

3:
##.
###
##.

4:
###
#..
###

5:
###
.#.
###

4x4: 0 0 0 0 2 0
12x5: 1 0 1 0 2 2
12x5: 1 0 1 0 3 2
"

pub fn input_parse_test() {
  let output = input |> day_12.input_parse()
  let expected = [
    day_12.Grid(width: 4, height: 4, values: [0, 0, 0, 0, 2, 0]),
    day_12.Grid(width: 12, height: 5, values: [1, 0, 1, 0, 2, 2]),
    day_12.Grid(width: 12, height: 5, values: [1, 0, 1, 0, 3, 2]),
  ]
  assert output == expected
}

pub fn task_1_test() {
  let input = input |> day_12.input_parse()
  assert day_12.task_1(input) == 2
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  let name = "Joe"
  let greeting = "Hello, " <> name <> "!"

  assert greeting == "Hello, Joe!"
}
