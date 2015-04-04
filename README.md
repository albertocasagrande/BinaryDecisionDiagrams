# BinaryDecisionDiagrams

[![Build Status](https://travis-ci.org/albertocasagrande/BinaryDecisionDiagrams.jl.svg?branch=master)](https://travis-ci.org/albertocasagrande/BinaryDecisionDiagrams.jl)

This package provides implementations for both Binary Decision Diagrams (BDD)
and Ordered Binary Decision Diagrams (OBDD) [Bryant86]. These data structures
are meant to represent Boolean functions. In particular, whenever the Boolean
functions are stored as OBDD, it is possible to:
* test logical equivalence between Boolean functions in time O(1)
* apply:
  * logical negation of the formula f in time O(|f|)
  * logical conjunction and exclusive disjunction of the formulae f1 and f2
    in time O(|f1|+|f2|)

[Bryant86] Randal E. Bryant. "Graph-Based Algorithms for Boolean Function Manipulation".
           IEEE Transactions on Computers, C-35(8):677–691, 1986.

## Installation

In julia, type
```julia
Pkg.add("BinaryDecisionDiagrams")
```

## Usage

In order to use the package, type in julia
```julia
using BinaryDecisionDiagrams
```

### Binary Decision Diagrams

Create a BDD terminal node by using the method `BDD` with a single Boolean
parameter  
```julia
b1=BDD(true)
"true"
```

Create a non-terminal node by using the method `BDD` with three parameters:
a variable name `var`, the BDD `low`, and the BDD `high`.  
```julia
b2=BDD("a",BDD(false),BDD(true))
"a"

b3=BDD("b",BDD("c",b1,b1),b2)
"(~b | (b & a))"
```

Partial evaluations of BDDs can be achieved through the method `restrict`.
```julia
restrict(b3,"b",true)
"a"

restrict(b3,"c",false)
"(~b | (b & a))"
```

`Ordering` is an abstract type that represents ordering between variables.
`ListOrdering`s are `Ordering`s built from arrays of variable names.
```julia
O=ListOrdering(["c","b","a"])
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

Whenever two OBDDs share the same variable ordering, Boolean
negation, conjunction, and disjunction can be applied to them as follows.
```julia
julia> o1&o2
"(a,b,c)->(~a & b)"

julia> o4=(o1|~o2)&o3
"(a,b,c)->(a & (b & c))"
```

Partial evaluations and logic equivalence are also available.
```julia
julia> restrict(o4,"b",true)
"(a,b,c)->(a & c)"

julia> b==OBDD("(a,b,c)->a&c&(b|~b)")
false

julia> a&b==OBDD("(a,b,c)->a&~b&(c|~c)")
true
```
