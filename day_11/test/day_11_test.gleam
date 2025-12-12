import day_11
import gleeunit

pub fn main() -> Nil {
  gleeunit.main()
}

const input_1 = "
aaa: you hhh
you: bbb ccc
bbb: ddd eee
ccc: ddd eee fff
ddd: ggg
eee: out
fff: out
ggg: out
hhh: ccc fff iii
iii: out
"

const input_2 = "
svr: aaa bbb
aaa: fft
fft: ccc
bbb: tty
tty: ccc
ccc: ddd eee
ddd: hub
hub: fff
eee: dac
dac: fff
fff: ggg hhh
ggg: out
hhh: out
"

pub fn task_2_test() {
  let output =
    input_2
    |> day_11.parse_input()
    |> day_11.task_2()
  assert output == 2
}

pub fn task_1_test() {
  let output =
    input_1
    |> day_11.parse_input
    |> day_11.task_1()

  assert output == 5
}
