import day_1.{Left, Right}
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

// gleeunit test functions end in `_test`
pub fn hello_world_test() {
  let name = "Joe"
  let greeting = "Hello, " <> name <> "!"

  assert greeting == "Hello, Joe!"
}

const input = "
L68
L30
R48
L5
R60
L55
L1
L99
R14
L82
"

pub fn input_parse_test() {
  let expected = [
    Left(68),
    Left(30),
    Right(48),
    Left(5),
    Right(60),
    Left(55),
    Left(1),
    Left(99),
    Right(14),
    Left(82),
  ]

  let output = input |> day_1.input_parse()
  assert output == expected
}

pub fn task_1_test() {
  let output =
    input
    |> day_1.input_parse()
    |> day_1.task_1()
  let expected = 3

  assert output == expected
}

pub fn task_2_test() {
  let output = input |> day_1.input_parse() |> day_1.task_2()
  assert output == 6
}
