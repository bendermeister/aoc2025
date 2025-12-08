import day_2
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
11-22,95-115,998-1012,1188511880-1188511890,222220-222224,
1698522-1698528,446443-446449,38593856-38593862,565653-565659,
824824821-824824827,2121212118-2121212124
"

pub fn repeats_55_test() {
  assert day_2.repeats(55)
}

pub fn repeats_1010_test() {
  assert day_2.repeats(1010)
}

pub fn repeats_1_test() {
  assert !day_2.repeats(1)
}

pub fn repeats_234234234_test() {
  assert day_2.repeats(234_234_234)
}

pub fn repeats10001000_test() {
  assert day_2.repeats(10_001_000)
}

pub fn input_parse_test() {
  let output = input |> day_2.parse_input()
  let expected = [
    #(11, 22),
    #(95, 115),
    #(998, 1012),
    #(1_188_511_880, 1_188_511_890),
    #(222_220, 222_224),
    #(1_698_522, 1_698_528),
    #(446_443, 446_449),
    #(38_593_856, 38_593_862),
    #(565_653, 565_659),
    #(824_824_821, 824_824_827),
    #(2_121_212_118, 2_121_212_124),
  ]
  assert output == expected
}

pub fn repeats_101_test() {
  assert !day_2.repeats(101)
}

pub fn task_1_test() {
  let output =
    input
    |> day_2.parse_input()
    |> day_2.task_1()
  let expected = 1_227_775_554
  assert output == expected
}

pub fn task_2_test() {
  let output = input |> day_2.parse_input |> day_2.task_2()
  let expected = 4_174_379_265
  assert output == expected
}
// pub fn task_2__test() {
//   let output = input |> day_2.task_2_()
//   let expected = 4_174_379_265
//   assert output == expected
// }
