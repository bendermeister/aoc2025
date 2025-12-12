import gleam/bool
import gleam/dict
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import simplifile
import util/palist

pub fn parse_line(input: String) -> #(List(Bool), List(List(Int)), List(Int)) {
  let input =
    input
    |> string.trim()
    |> string.drop_start(1)
    |> string.drop_end(1)

  let assert Ok(#(lights, rest)) = input |> string.split_once("]")
  let assert Ok(#(buttons, jolts)) = rest |> string.split_once("{")

  let lights =
    lights
    |> string.trim()
    |> string.to_graphemes()
    |> list.map(fn(x) {
      case x {
        "#" -> True
        "." -> False
        _ -> panic
      }
    })

  let buttons =
    buttons
    |> string.trim()
    |> string.split(" ")
    |> list.map(fn(x) {
      x
      |> string.drop_start(1)
      |> string.drop_end(1)
      |> string.split(",")
      |> list.map(int.parse)
      |> result.partition()
      |> pair.first()
      |> list.reverse()
    })

  let jolts =
    jolts
    |> string.trim()
    |> string.split(",")
    |> list.map(int.parse)
    |> result.partition
    |> pair.first
    |> list.reverse

  #(lights, buttons, jolts)
}

pub fn parse(input: String) -> List(#(List(Bool), List(List(Int)), List(Int))) {
  input
  |> string.trim()
  |> string.split("\n")
  |> list.map(parse_line)
}

pub fn button_press(buttons: List(List(Int)), number_of_lights: Int) {
  let acc =
    buttons
    |> list.flatten()
    |> list.fold(dict.new(), fn(acc, button) {
      acc
      |> dict.get(button)
      |> result.unwrap(False)
      |> bool.negate
      |> dict.insert(acc, button, _)
    })

  list.range(0, number_of_lights - 1)
  |> list.map(fn(x) { dict.get(acc, x) |> result.unwrap(False) })
}

pub fn button_press_2(buttons: List(Int), number_of_lights: Int) {
  let acc =
    buttons
    |> list.fold(dict.new(), fn(acc, button) {
      acc
      |> dict.get(button)
      |> result.unwrap(0)
      |> int.add(1)
      |> dict.insert(acc, button, _)
    })

  list.range(0, number_of_lights - 1)
  |> list.map(fn(x) { dict.get(acc, x) |> result.unwrap(0) })
}

pub fn task_1(input: List(#(List(Bool), List(List(Int)), List(Int)))) {
  input
  |> list.map(fn(x) {
    let #(lights, buttons, _) = x
    let lights_length = lights |> list.length

    list.range(1, buttons |> list.length)
    |> list.drop_while(fn(take) {
      buttons
      |> list.combinations(take)
      |> list.all(fn(perm) { button_press(perm, lights_length) != lights })
    })
    |> list.first()
    |> result.unwrap(-1)
  })
  |> int.sum()
}

pub type Gauss {
  Gauss(
    width: Int,
    height: Int,
    matrix: dict.Dict(#(Int, Int), Float),
    next_unsolved: Int,
    free: List(Int),
  )
}

pub fn gauss_get_vars(gauss: Gauss) {
  gauss
  |> gauss_get_col(gauss.width - 1)
}

pub fn gauss_is_solved(gauss: Gauss) {
  gauss.next_unsolved >= gauss.width - 1
}

fn dict_get_assert(dict: dict.Dict(a, b), key: a) -> b {
  let assert Ok(value) = dict.get(dict, key)
  value
}

pub fn gauss_to_string(gauss: Gauss) {
  let matrix =
    gauss.matrix
    |> dict.map_values(fn(_, x) {
      x |> float.to_precision(2) |> float.to_string()
    })

  let pad =
    matrix
    |> dict.to_list()
    |> list.map(pair.second)
    |> list.map(string.length)
    |> list.fold(0, int.max)

  list.range(0, gauss.height - 1)
  |> list.map(fn(row) {
    list.range(0, gauss.width - 1)
    |> list.map(fn(col) { matrix |> dict_get_assert(#(row, col)) })
    |> list.map(string.pad_start(_, with: " ", to: pad))
    |> string.join(", ")
  })
  |> string.join("\n")
}

pub const input = [
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

pub fn gauss_get_row(gauss: Gauss, row: Int) -> List(Float) {
  assert row < gauss.height

  list.range(0, gauss.width - 1)
  |> list.map(pair.new(row, _))
  |> list.map(fn(x) {
    let assert Ok(val) = gauss.matrix |> dict.get(x)
    val
  })
}

pub fn gauss_row_insert(gauss: Gauss, row_index: Int, row: List(Float)) {
  assert list.length(row) == gauss.width
  assert row_index < gauss.height

  let matrix =
    row
    |> list.index_map(fn(value, col_index) { #(#(row_index, col_index), value) })
    |> list.fold(gauss.matrix, fn(matrix, x) {
      let #(pos, value) = x
      dict.insert(matrix, pos, value)
    })

  Gauss(..gauss, matrix:)
}

pub fn gauss_swap_rows(gauss: Gauss, a: Int, b: Int) {
  assert a < gauss.height
  assert b < gauss.height

  let a_row = gauss_get_row(gauss, a)
  let b_row = gauss_get_row(gauss, b)

  gauss
  |> gauss_row_insert(b, a_row)
  |> gauss_row_insert(a, b_row)
}

pub fn gauss_get_col(gauss: Gauss, col_index: Int) -> List(Float) {
  assert col_index < gauss.width

  list.range(0, gauss.height - 1)
  |> list.map(fn(row_index) {
    let assert Ok(value) = dict.get(gauss.matrix, #(row_index, col_index))
    value
  })
}

pub fn gauss_increment_next_unsolved(gauss: Gauss) {
  Gauss(..gauss, next_unsolved: gauss.next_unsolved + 1)
}

pub fn gauss_update(gauss: Gauss) {
  // when we have nothing to solve we have nothing to solve
  use <- bool.guard(when: gauss_is_solved(gauss), return: gauss)
  use <- bool.guard(when: gauss.next_unsolved >= gauss.height, return: gauss)

  let target_row =
    list.range(gauss.next_unsolved, gauss.height - 1)
    |> list.map(pair.new(_, gauss.next_unsolved))
    |> list.filter(fn(element) {
      let assert Ok(element) = dict.get(gauss.matrix, element)
      float.loosely_compare(element, 0.0, epsilon) != order.Eq
    })
    // |> list.map(fn(element) {
    //   let assert Ok(cost) =
    //     dict.get(gauss.matrix, #(element.0, gauss.width - 1))
    //   #(cost, element)
    // })
    // |> list.sort(fn(a, b) { float.compare(a.0, b.0) })
    |> list.first()
    // |> result.map(pair.second)
    |> result.map(pair.first)

  case target_row {
    Ok(target_row_index) -> {
      let target_row = gauss_get_row(gauss, target_row_index)

      // normalize target_row not the element with index next_unsolved == 1
      let assert Ok(divisor) =
        target_row |> list.drop(gauss.next_unsolved) |> list.first()
      let target_row =
        target_row
        |> list.map(fn(x) { x /. divisor })

      // insert target row back into the matrix and swap the target row with
      // the row at next_unsolved now we have a 1 at position #(next_unsolved,
      // next_unsolved)
      let gauss =
        gauss_row_insert(gauss, target_row_index, target_row)
        |> gauss_swap_rows(target_row_index, gauss.next_unsolved)
      // now we need to normalize the next_unsolved column so it only contains 1 1

      gauss_get_col(gauss, gauss.next_unsolved)
      |> list.index_map(fn(element, row_index) {
        let multiplicant = case row_index == gauss.next_unsolved {
          False -> element
          True -> 0.0
        }
        let diff = target_row |> list.map(fn(x) { x *. multiplicant })
        gauss_get_row(gauss, row_index)
        |> list.map2(diff, fn(x, y) { x -. y })
        |> pair.new(row_index, _)
      })
      |> list.fold(gauss, fn(gauss, row) {
        let #(row_index, row) = row
        gauss_row_insert(gauss, row_index, row)
      })
      |> gauss_increment_next_unsolved()
      |> gauss_update()
    }
    Error(_) -> gauss
  }
}

pub fn gauss_assume_next_unsolved(gauss: Gauss, next_unsolved: Int) {
  let gauss = Gauss(..gauss, height: gauss.height + 1)

  list.repeat(0, gauss.width)
  |> list.index_map(fn(_, col_index) {
    case col_index == gauss.next_unsolved {
      True -> 1
      False ->
        case col_index == gauss.width - 1 {
          True -> next_unsolved
          False -> 0
        }
    }
  })
  |> list.map(int.to_float)
  |> gauss_row_insert(gauss, gauss.height - 1, _)
}

pub const epsilon = 0.00001

pub fn task_2_backtrack(gauss: Gauss, var_upper_bound: Int, max_cost: Int) {
  let gauss = gauss |> gauss_update()

  let is_solved = gauss_is_solved(gauss)
  use <- bool.lazy_guard(when: is_solved, return: fn() {
    gauss_get_vars(gauss)
    |> list.fold_until(Ok(0), fn(sum, value) {
      let rounded = value |> float.round |> int.to_float()
      let is_eq = float.loosely_compare(value, rounded, epsilon) == order.Eq
      use <- bool.guard(when: !is_eq, return: Error(Nil) |> list.Stop)

      let value = value |> float.round

      case 0 <= value {
        True ->
          case sum {
            Error(_) -> Error(Nil) |> list.Stop
            Ok(sum) -> Ok(sum + value) |> list.Continue
          }
        False -> Error(Nil) |> list.Stop
      }
    })
    |> result.unwrap(max_cost)
    |> int.min(max_cost)
  })

  list.range(0, var_upper_bound)
  |> list.map(gauss_assume_next_unsolved(gauss, _))
  |> list.fold(max_cost, fn(max_cost, gauss) {
    task_2_backtrack(gauss, var_upper_bound, max_cost)
  })
}

pub fn task_2_line(input: #(a, List(List(Int)), List(Int))) {
  let #(_, buttons, joltage) = input

  let matrix =
    buttons
    |> list.map(set.from_list)
    |> list.map(fn(button) {
      list.range(0, joltage |> list.length |> int.subtract(1))
      |> list.map(set.contains(button, _))
      |> list.map(fn(x) {
        case x {
          False -> 0
          True -> 1
        }
      })
    })
    |> list.append([joltage])
    |> list.transpose
    |> list.index_map(fn(row, row_index) {
      list.index_map(row, fn(value, col_index) {
        #(#(row_index, col_index), value)
      })
    })
    |> list.flatten()

  let #(height, width) =
    matrix
    |> list.fold(#(0, 0), fn(acc, x) {
      #(int.max(acc.0, x.0.0), int.max(acc.1, x.0.1))
    })
    |> pair.map_first(int.add(_, 1))
    |> pair.map_second(int.add(_, 1))

  let matrix =
    matrix |> list.map(pair.map_second(_, int.to_float)) |> dict.from_list()

  let max_cost = joltage |> int.sum()
  let var_upper_bound = joltage |> list.max(int.compare) |> result.unwrap(-1)

  // let gauss =
  Gauss(width:, height:, matrix:, next_unsolved: 0, free: [])
  |> task_2_backtrack(var_upper_bound, max_cost)
  // |> gauss_update()
  // |> gauss_assume_next_unsolved(10)
  // |> gauss_update()
  // |> gauss_assume_next_unsolved(2)
  // |> gauss_update()

  // gauss
  // |> gauss_to_string
  // |> io.println()
  // // |> gauss_update()
  // // |> task_2_backtrack(var_upper_bound, max_cost)
  // 2
}

pub fn task_2(input: List(#(a, List(List(Int)), List(Int)))) -> Int {
  input
  |> palist.map(1, task_2_line)
  |> int.sum()
}

pub fn main() -> Nil {
  let assert Ok(input) = simplifile.read("input.txt")
  let input = input |> parse()
  // let assert Ok(input) = input |> list.drop(4) |> list.first()
  // task_2_line(input)

  // Nil
  io.print("Task 1: ")
  input |> task_1 |> int.to_string |> io.println
  io.print("Task 2: ")
  io.println("")
  input |> task_2 |> int.to_string |> io.println
}
