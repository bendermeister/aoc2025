import gleam/bool
import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/order
import gleam/pair
import gleam/result
import gleam/set
import gleam/string
import simplifile
import util/palist

pub type Configuration {
  Configuration(
    desired_state: dict.Dict(Int, Bool),
    commands: List(List(Int)),
    jolts: List(Int),
  )
}

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

pub type Variable {
  Variable(Int)
}

pub fn variable_to_string(variable: Variable) {
  let Variable(inner) = variable
  "v" <> int.to_string(inner)
}

pub type Constraint {
  Constraint(variables: set.Set(Variable), value: Int)
}

pub fn constraint_to_string(constraint: Constraint) {
  let vars =
    constraint.variables
    |> set.to_list
    |> list.map(variable_to_string)
    |> string.join("+")
    |> string.to_option()
    |> option.unwrap("0")

  let value = constraint.value |> int.to_string

  vars <> " = " <> value
}

pub type ProblemSpace {
  ProblemSpace(
    cost: Int,
    // constants: dict.Dict(Variable, Int),
    variables: List(Variable),
    constraints: List(Constraint),
  )
}

pub fn problem_space_to_string(ps: ProblemSpace) {
  // let constants =
  //   ps.constants
  //   |> dict.to_list()
  //   |> list.map(fn(constant) {
  //     let #(variable, value) = constant
  //     let variable = variable |> variable_to_string()
  //     let value = value |> int.to_string()
  //     variable <> " = " <> value
  //   })
  //   |> string.join("\n")

  let variables =
    ps.variables
    |> list.map(variable_to_string)
    |> string.join(", ")

  let constraints =
    ps.constraints
    |> list.map(constraint_to_string)
    |> string.join("\n")

  // constants <> 
  "\n" <> variables <> "\n" <> constraints
}

pub fn problem_space_update(
  ps: ProblemSpace,
  variable: Variable,
  value: Int,
) -> ProblemSpace {
  // never call this function when variable is already a constant
  // assert Error(Nil) == dict.get(ps.constants, variable)
  assert ps.variables |> list.contains(variable)
  assert 0 <= value

  // variable now becomes a constant
  // - add it to constants with assigned value
  // - remove it from variables
  // let constants = dict.insert(ps.constants, variable, value)
  let variables = list.filter(ps.variables, fn(x) { x != variable })
  let cost = ps.cost + value

  let constraints =
    // update constraints
    // - if variable a is present in constraint remove it and adjust the
    //   constraint value
    list.map(ps.constraints, fn(constraint) {
      let is_contained = constraint.variables |> set.contains(variable)
      use <- bool.guard(when: !is_contained, return: constraint)

      let variables = constraint.variables |> set.delete(variable)
      let value = constraint.value - value
      Constraint(variables:, value:)
    })
    // next: normalize constraints
    // constraints of the form Constraint([a, b, ...], 0) can be normalized to
    // [Constraint([a], 0), Constraint([b], 0), ...]
    // note: this will also remove any constraint of the pattern 
    // Constraint([], 0) which is fine because these constraints would always
    // hold
    |> list.flat_map(fn(constraint) {
      use <- bool.guard(when: constraint.value != 0, return: [constraint])
      constraint.variables
      |> set.to_list()
      |> list.map(fn(variable) {
        Constraint(variables: set.new() |> set.insert(variable), value: 0)
      })
    })

  // let ps = ProblemSpace(constants:, variables:, constraints:, cost:)
  let ps = ProblemSpace(variables:, constraints:, cost:)

  // ps
  // |> problem_space_to_string()
  // |> io.println()
  // io.println("===========================")

  problem_space_update_rec(ps)
}

pub fn problem_space_cost(ps: ProblemSpace) {
  ps.cost
}

pub fn problem_space_variable_upper_bound(ps: ProblemSpace, variable: Variable) {
  assert ps.variables |> list.contains(variable)

  ps.constraints
  |> list.filter(fn(constraint) {
    constraint.variables |> set.contains(variable)
  })
  |> list.map(fn(constraint) { constraint.value })
  |> list.reduce(int.min)
  |> result.unwrap(0)
}

pub fn problem_space_pop(ps: ProblemSpace) {
  ps.variables
  |> list.first()
  |> result.map(fn(variable) {
    let upper_bound = problem_space_variable_upper_bound(ps, variable)
    #(variable, upper_bound)
  })
}

pub fn task_2_line(input: #(a, List(List(Int)), List(Int))) {
  let #(_, buttons, joltage) = input
  let joltage_length = joltage |> list.length

  let variables =
    buttons
    |> list.index_map(fn(button, i) { #(button |> list.length, Variable(i)) })
    |> list.sort(fn(a, b) { int.compare(a.0, b.0) |> order.negate })
    |> list.map(pair.second)

  let constraints =
    buttons
    |> list.map(set.from_list)
    |> list.map(fn(button) {
      list.range(0, joltage_length - 1)
      |> list.map(set.contains(button, _))
    })
    |> list.transpose()
    |> list.map(fn(constraint) {
      constraint
      |> list.zip(variables)
      |> list.filter(fn(x) { x.0 })
      |> list.map(pair.second)
      |> set.from_list()
    })
    |> list.map2(joltage, fn(variables, value) {
      Constraint(variables:, value:)
    })

  let upper_bound = joltage |> int.sum()

  // ProblemSpace(constants: dict.new(), variables:, constraints:, cost: 0)
  ProblemSpace(variables:, constraints:, cost: 0)
  |> task_2_backtrack(upper_bound)
}

pub fn problem_space_is_solved(problem_space: ProblemSpace) {
  problem_space.constraints |> list.length == 0
}

pub fn task_2(input: List(#(a, List(List(Int)), List(Int)))) {
  input
  |> palist.map(1, task_2_line)
  |> int.sum()
}

pub fn task_2_backtrack(problem_space: ProblemSpace, max_cost: Int) {
  // problem_space
  // |> problem_space_to_string()
  // |> io.println()
  //
  // io.println("Max Cost: " <> int.to_string(max_cost))
  //
  // io.println("====================")
  //
  let is_feasible = is_problem_space_feasible(problem_space)
  use <- bool.guard(when: !is_feasible, return: max_cost)

  let cost = problem_space_cost(problem_space)
  use <- bool.guard(when: max_cost <= cost, return: max_cost)

  let is_solved = problem_space_is_solved(problem_space)
  use <- bool.guard(when: is_solved, return: cost)

  case problem_space_pop(problem_space) {
    Ok(#(variable, max)) ->
      list.range(max, 0)
      |> list.map(problem_space_update(problem_space, variable, _))
      |> list.fold(max_cost, fn(max_cost, problem_space) {
        task_2_backtrack(problem_space, max_cost)
        |> int.min(max_cost)
      })
    Error(_) -> max_cost
  }
}

pub fn is_problem_space_feasible(ps: ProblemSpace) {
  // if any constraint is under zero it can never be fullfilled
  let all_leq_zero =
    ps.constraints |> list.all(fn(constraint) { 0 <= constraint.value })
  use <- bool.guard(when: !all_leq_zero, return: False)

  // if a constraint needs to still be fullfilled without variables it can
  // never be fullfilled
  let any_open_without_variables =
    ps.constraints
    |> list.any(fn(constraint) {
      let is_open = constraint.value != 0
      let is_empty = constraint.variables |> set.size() == 0
      is_open && is_empty
    })
  use <- bool.guard(when: any_open_without_variables, return: False)

  True
}

fn problem_space_update_rec(ps: ProblemSpace) -> ProblemSpace {
  // if the problem space is no longer feasible we can stop trying to
  // recursively update it
  let is_feasible = is_problem_space_feasible(ps)
  use <- bool.guard(when: !is_feasible, return: ps)

  ps.constraints
  |> list.filter(fn(constraint) { constraint.variables |> set.size() == 1 })
  |> list.first()
  |> result.map(fn(constraint) {
    let assert Ok(variable) =
      constraint.variables |> set.to_list() |> list.first()
    let value = constraint.value

    problem_space_update(ps, variable, value)
  })
  |> result.unwrap(ps)
}

pub fn main() -> Nil {
  let assert Ok(input) = simplifile.read("input.txt")

  let input = input |> parse()
  io.print("Task 1: ")
  input |> task_1 |> int.to_string |> io.println
  io.print("Task 2: ")
  input |> task_2 |> int.to_string |> io.println
  // bench.run(
  //   [bench.Input("data", input)],
  //   [
  //     // bench.Function("task_1", task_1),
  //     bench.Function("task_2", task_2),
  //   ],
  //   [
  //     bench.Duration(10_000),
  //     bench.Warmup(10),
  //   ],
  // )
  // |> bench.table([
  //   bench.Mean,
  //   bench.SD,
  //   bench.P(99),
  // ])
  // |> io.println
}
