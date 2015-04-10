# BinaryDecisionDiagrams

[![Build Status](https://travis-ci.org/albertocasagrande/BinaryDecisionDiagrams.svg?branch=master)](https://travis-ci.org/albertocasagrande/BinaryDecisionDiagrams)
[ ![License] [license-image] ] [license]

This package provides implementations for both [Binary Decision Diagrams (BDD)
and Ordered Binary Decision Diagrams (OBDD)](Bryant86). These data structures
are meant to represent binary/Boolean functions.

## Theory

Both BDD and OBDD are [directed graphs][digraph]

### Binary Decision Diagrams

BDD nodes can be either **terminal** or **non-terminal** nodes.
Terminal nodes are labelled by a *binary value* and they are not source of any
edge. If `t` is a terminal node, we write `t.value` to denote the value of `t`.
Non-terminal nodes are labelled by a *variable* name and they
are source of two edges called *low* and *high*. If `n` is a non-terminal
node, we write `n.var`, `n.low`, and `n.high` to denote the variable name,
the edge low, and the edge high of the node `n`.

Any terminal node `t` represents the binary function `t.value`, while
any non-terminal node `n` encodes the binary function
`(~n.var & f_l) | (n.var & f_h)` where `f_l` and `f_h` are the binary
functions associated to `n.low` and `n.high`, respectively.

A BDD **respects a variable ordering <** whenever `n.var` < `n.low.var`
for all non-terminal nodes `n` and `n.low` and `n.var` < `n.high.var`
for all non-terminal nodes `n` and `n.high`.

### Ordered Binary Decision Diagrams

The logical equivalence of two binary functions can be reduced to the
existence of an isomorphism between the BDD encoding them under three conditions:

1. the two BDDs respect the same variable ordering;
2. `n.low` and `n.high` are different nodes for any non-terminal node `n` in
   both the BDDs;
3. for each of the BDDs and for all pairs of nodes in it, there is no
   isomophism between them.

OBDDs are BDDs equipped of a variable ordering and satisfying condition 2. and 3.

Whenever two binary functions `f_1` and `f_2` are stored as OBDD and they share
the same variable ordering, it is possible to:
* test logical equivalence between `f_1` and `f_2` in time `O(1)`;
* compute the OBDD that represents:
  * the bitwise negation of the formula `f_1` in time `O(|f_1|)`;
  * the bitwise binary combinations of the functions `f_1` and `f_2` in time `O(|f_1|+|f_2|)`.

<a name="Bryant86">[Bryant86] Randal E. Bryant. "Graph-Based Algorithms for Boolean Function Manipulation".
           IEEE Transactions on Computers, C-35(8):677–691, 1986.

[digraph]: https://en.wikipedia.org/wiki/Directed_graph

## Installation

In julia, type
```julia
julia> Pkg.clone("git://github.com/albertocasagrande/BinaryDecisionDiagrams.git")
```

## Usage

In order to use the package, type in julia
```julia
using BinaryDecisionDiagrams
```

### Binary Decision Diagrams

Create a BDD terminal node by using the method `BDD` with a single binary parameter  
```julia
julia> b1=BDD(1)
"1"
```

Create a non-terminal node by using the method `BDD` with three parameters:
a variable name `var`, the BDD `low`, and the BDD `high`.  
```julia
julia> b2=BDD("a",BDD(0),BDD(true))
"a"

julia> b3=BDD("b",BDD("c",b1,b1),b2)
"(~b | (b & a))"
```

Partial evaluations of BDDs can be achieved through the method `restrict`.
```julia
julia> restrict(b3,"b",1)
"a"

julia> restrict(b3,"c",false)
"(~b | (b & a))"
```

`Ordering` is an abstract type that represents ordering between variables.
`ListOrdering`s are `Ordering`s built from arrays of variable names.
```julia
julia> O=ListOrdering(["c","b","a"])
"(c,b,a)"
```

### Ordered Binary Decision Diagrams

The type `OBDD` has four main constructors:
```julia
julia> OBDD(O,b3)
"(c,b,a)->(~b | (b & a))"

julia> o0=OBDD(O,"~a | ~b")
"(c,b,a)->(~b | (b & ~a))"

julia> o1=OBDD(["a","b","c"],"~a & b")
"(a,b,c)->(~a & b)"

julia> o2=OBDD(["a","b","c"],"~a | ~b")
"(a,b,c)->(~a | (a & ~b))"

julia> o3=OBDD("(a,b,c)->(a & ~b) | (c&a)")
"(a,b,c)->(a & (~b | (b & c)))"
```

If two OBDDs share the same variable ordering, bitwise
negation, conjunction, and disjunction can be applied to them as follows.
```julia
julia> o1&o2
"(a,b,c)->(~a & b)"

julia> o4=(o1|~o2)&o3
"(a,b,c)->(a & (b & c))"

julia> o1$~o4
"(a,b,c)->((~a & ~b) | (a & (~b | (b & ~c))))"
```

Partial evaluations and logic equivalence are also available.
```julia
julia> restrict(o4,"b",1)
"(a,b,c)->(a & c)"

julia> o3==OBDD("(a,b,c)->a&c&(b|~b)")
false

julia> o2&o3==OBDD("(a,b,c)->a&~b&(c|~c)")
true
```

Whenever the function contains a variable that is not in the ordering, an
ArgumentError is thrown.
```julia
julia> OBDD("(a,b,c)->r")
ERROR: ArgumentError("r is not in (a,b,c)")
 in OBDD at /Users/house/.julia/v0.3/BinaryDecisionDiagrams/src/parsing.jl:91

julia> OBDD(["a"],b3)
ERROR: ArgumentError("b is not in (a)")
 in OBDD at /Users/house/.julia/v0.3/BinaryDecisionDiagrams/src/OBDD.jl:10
```

If the BDD does not respect the variable ordering, the constructors
`OBDD(::Ordering,::BDDNode)` and `OBDD(::Array{ASCIIString,1},::BDDNode)`
throw an exception.
```julia
julia> OBDD(["a","b"],b3)
ERROR: ArgumentError("(~b | (b & a)) does not respect (a,b)")
 in OBDD at /Users/house/.julia/v0.3/BinaryDecisionDiagrams/src/OBDD.jl:10
```

However, given an OBDD `A`, a new OBDD that represents
the same function of `A`, but has a different variable ordering can be built.
```julia
julia> o5=OBDD(["b","a"],b3)
"(b,a)->(~b | (b & a))"

julia> o6=changeordering(o4,["a","b"])
"(a,b)->((~a & ~b) | a)"
```

Two OBDDs having different variable ordering can be neither compared nor
parameters of a bitwise binary function.

```julia
julia> o5==o6
ERROR: ArgumentError("(b,a)->(~b | (b & a)) and (a,b)->((~a & ~b) | a) do not share the same ordering")
 in == at /Users/house/.julia/v0.3/BinaryDecisionDiagrams/src/OBDD.jl:179

julia> o5==OBDD(["c"],"~c")
ERROR: ArgumentError("(b,a)->(~b | (b & a)) and (c)->(~c) do not share the same ordering")
 in == at /Users/house/.julia/v0.3/BinaryDecisionDiagrams/src/OBDD.jl:179

julia> o5&OBDD(["c"],"~c")
ERROR: ArgumentError("(b,a)->(~b | (b & a)) and (c)->(~c) do not share the same ordering")
 in applyoperator at /Users/house/.julia/v0.3/BinaryDecisionDiagrams/src/OBDD.jl:89
 in & at /Users/house/.julia/v0.3/BinaryDecisionDiagrams/src/OBDD.jl:113
```

#### Dynamic

In order to either compare or pass as arguments to a bitwise binary functions
two OBDDs that do not share the same variable ordering, we can enable
the *dynamic variable ordering*. In such case, two new OBDDs, having a common
ordering and representing the functions encoded by the original OBDDs,
are built automatically and the comparison or the bitwise function are applied
to them.

```julia
julia> set_dynamic_ordering()
"Dynamic variable ordering has been enabled"

julia> o5==o6
true

julia> o5==OBDD(["c"],"~c")
false

julia> o5&OBDD(["c"],"~c")
"(b,a,c)->((~b & ~c) | (b & (a & ~c)))"
```

Dynamic variable ordering is really handy, nevertheless, it may take time
`O(2^{|variables|})` and, thus, it should be used sparingly.

Dynamic variable ordering can be disabled by using the command
`set_static_ordering()`.

```julia
julia> set_static_ordering()
"Dynamic variable ordering has been disabled"

julia> o5==o6
ERROR: ArgumentError("(b,a)->(~b | (b & a)) and (a,b)->((~a & ~b) | a) do not share the same ordering")
 in == at /Users/house/.julia/v0.3/BinaryDecisionDiagrams/src/OBDD.jl:179
```

## Copyright and License

The BinaryDecisionDiagrams package is licensed under the MIT "Expat" License:

> Copyright (c) 2015: Alberto Casagrande.
>
> Permission is hereby granted, free of charge, to any person obtaining
> a copy of this software and associated documentation files (the
> "Software"), to deal in the Software without restriction, including
> without limitation the rights to use, copy, modify, merge, publish,
> distribute, sublicense, and/or sell copies of the Software, and to
> permit persons to whom the Software is furnished to do so, subject to
> the following conditions:
>
> The above copyright notice and this permission notice shall be
> included in all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
> EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
> MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
> IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
> CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
> TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
> SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


[license-image]: https://img.shields.io/:license-mit-blue.svg
[license]: https://github.com/albertocasagrande/BinaryDecisionDiagrams/blob/master/LICENSE.md
