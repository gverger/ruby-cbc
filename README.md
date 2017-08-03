[![Build Status](https://travis-ci.org/gverger/ruby-cbc.svg?branch=master)](https://travis-ci.org/gverger/ruby-cbc)
# Ruby-Cbc

This gem is using Cbc, an Integer Linear Programming Library, to provide optimization problems solving
to ruby. With Ruby-Cbc, you can model you problem, solve it and find conflicts in case of infeasibility.

It uses the version 2.9.9 of Cbc, and requires the version 2.9.9 of gem cbc-wrapper.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ruby-cbc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ruby-cbc

The gem includes a version of the Coin-Or Cbc library. If the system on which
it is installed is not Linux 64bits, it downloads the library sources and
recompiles them at installation.

It also works on Heroku.

## Usage

```ruby
# The same Brief Example as found in section 1.3 of 
# glpk-4.44/doc/glpk.pdf.
#
# maximize
#   z = 10 * x1 + 6 * x2 + 4 * x3
#
# subject to
#   p:      x1 +     x2 +     x3 <= 100
#   q: 10 * x1 + 4 * x2 + 5 * x3 <= 600
#   r:  2 * x1 + 2 * x2 + 6 * x3 <= 300
#
# where all variables are non-negative
#   x1 >= 0, x2 >= 0, x3 >= 0
#
m = Cbc::Model.new
x1, x2, x3 = m.int_var_array(3, 0..Cbc::INF)

m.maximize(10 * x1 + 6 * x2 + 4 * x3)

m.enforce(x1 + x2 + x3 <= 100)
m.enforce(10 * x1 + 4 * x2 + 5 * x3 <= 600)
m.enforce(2 * x1 + 2 * x2 + 6* x3 <= 300)

p = m.to_problem

p.solve

if ! p.proven_infeasible?
  puts "x1 = #{p.value_of(x1)}"
  puts "x2 = #{p.value_of(x2)}"
  puts "x3 = #{p.value_of(x3)}"
end
```
### Modelling

Let's have a model :
```ruby
model = Cbc::Model.new
```
#### The variables

3 variable kinds are available:
```ruby
x = model.bin_var(name: "x")        # a binary variable (i.e. can take values 0 and 1)
y = model.int_var(L..U, name: "y")  # a integer variable, L <= y <= U
z = model.cont_var(L..U, name: "z") # a continuous variable, L <= z <= U
```
Name is optional and used only when displaying the model.

If you don't specify the range, the variables are free.
You can also use ```Cbc::INF``` as the infinity bound.

Each one of these 3 kinds have also an array method that generate several variables.
For instance to generate 3 positive integer variables named x, y and z :
```ruby
x, y, z = model.int_var_array(3, 0..Cbc::INF, names: ["x", "y", "z"])
```

#### The constraints

You can enforce constraints:
```ruby
model.enforce(x + y - z <= 10)
```
You are not restricted to usual linear programming rules when writing a constraint.
Usually you would have to write ```x - y = 0``` to express ```x = y```.
Ruby-Cbc allows you to put variables and constants on both sides of the comparison operator. You can write
```ruby
model.enforce(x - y == 0)
model.enforce(x == y)
model.enforce(x + 2 == y + 2)
model.enforce(0 == x - y)
```

Ruby-Cbc allows you to name your constraints. Beware that their name is not an unique id. It is only a helper
for human readability, and several constraints can share the same function name.
```ruby
model.enforce(my_function_name: x + y <= 50)
model.constraints.map(&:to_function_s) # => ["my_function_name(x, y)"]
```

Linear constraints are usually of the form
```ruby
a1 * x1 + a2 * x2 + ... + an * xn <= C
a1 * x1 + a2 * x2 + ... + an * xn >= C
a1 * x1 + a2 * x2 + ... + an * xn == C
```

With Ruby-Cbc you can write
```ruby
2 * (2 + 5 * x) + 4 * 5 + 1 == 1 + 4 * 5 * y
```
The (in)equation must still be a **linear** (in)equation, you cannot multiply two variables !

#### Objective

You can set the objective:
```ruby
model.maximize(3 * x + 2 * y)
model.minimize(3 * x + 2 * y)
```

#### Displaying the model

the `Model` instances have a `to_s` method. You can then run
```ruby
puts model
```
The model will be printed in LP format.

For instance:
```
Maximize
  + 10 x1 + 6 x2 + 4 x3

Subject To
  + x1 + x2 + x3 <= 100
  + 10 x1 + 4 x2 + 5 x3 <= 600
  + 2 x1 + 2 x2 + 6 x3 <= 300

Bounds
  0 <= x1 <= +inf
  0 <= x2 <= +inf
  0 <= x3 <= +inf

Generals
  x1
  x2
  x3

End
```

### Solving

To solve the model, you need to first transform it to a problem.
```ruby
problem = model.to_problem
```

You can define a time limit to the resolution
```ruby
problem.set_time_limit(nb_seconds)
```

You can solve the Linear Problem
```ruby
problem.solve
```

You can specify arguments that match the cbc command line
```ruby
problem.solve(sec: 60) # equivalent to $ cbc -sec 60
problem.solve(log: 1)  # equivalent to $ cbc -log 1
```
For more examples of available options, if `coinor-cbc` is installed run

    $ cbc

then type `?`

Once `problem.solve` has finished you can query the status:
```ruby
problem.proven_infeasible?  # will tell you if the problem has no solution
problem.proven_optimal?     # will tell you if the problem is solved optimally
problem.time_limit_reached? # Will tell you if the solve timed out
```

To have the different values, do
```ruby
problem.objective_value # Will tell you the value of the best objective
problem.best_bound      # Will tell you the best known bound
                        # if the bound equals the objective value, the problem is optimally solved
problem.value_of(var)   # will tell you the computed value or a variable
```

### Finding conflicts

Sometimes a problem has no feasible solution. In this case, one may wonder what is the minimum subset of conflicting
inequations. For this prupose, you can use
```ruby
problem.find_conflict      # Will return an array of constraints that form an unsatifiable set
problem.find_conflict_vars # Will return all variables involved in the unsatisfiable minimum set of constraints
```
It finds a minimum subset of constraints that make the problem unsatisfiable. Note that there could be several of them,
but the solver only computes the first one it finds. Note also that it does so by solving several instances
of relaxed versions of the problem. It might take some time! It is based on QuickXplain
(http://dl.acm.org/citation.cfm?id=1597177).

One way to see the results nicely could be
```ruby
problem.find_conflict.map(&:to_function_s)
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gverger/ruby-cbc.

