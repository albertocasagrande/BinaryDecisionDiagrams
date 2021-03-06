function parsebinaryexp(ordering::Ordering,value::BinBoolType)
  return OBDD(ordering,value)
end

function parsebinaryexp(ordering::Ordering,var::Symbol)
  return OBDD(ordering,BDD(string(var),BDD(false),BDD(true)))
end

function parseordering(ordering::Expr)
  if ordering.head != :tuple
    throw(Meta.ParseError("expected a tuple, got $(ordering)"))
  end

  return ListOrdering(String[string(var) for var in ordering.args])
end

function parsebinaryexp(ordering::Ordering,binaryexp::Expr)
  if binaryexp.head == :&&
    return (parsebinaryexp(ordering,binaryexp.args[1])&
            parsebinaryexp(ordering,binaryexp.args[2]))
  end

  if binaryexp.head == :||
    return (parsebinaryexp(ordering,binaryexp.args[1])|
            parsebinaryexp(ordering,binaryexp.args[2]))
  end

  if binaryexp.head == :->
    return ((~parsebinaryexp(ordering,binaryexp.args[1]))|
            parsebinaryexp(ordering,binaryexp.args[2].args[2]))
  end

  if binaryexp.head != :call
    throw(Meta.ParseError("expected a bitwise binary operator, got $(binaryexp.head)"))
  end

  if binaryexp.args[1] == :~ || binaryexp.args[1] == :!
    return ~parsebinaryexp(ordering,binaryexp.args[2])
  end

  if binaryexp.args[1] == :& || binaryexp.args[1] == :*
    return (parsebinaryexp(ordering,binaryexp.args[2])&
            parsebinaryexp(ordering,binaryexp.args[3]))
  end

  if binaryexp.args[1] == :| || binaryexp.args[1] == :+
    return (parsebinaryexp(ordering,binaryexp.args[2])|
            parsebinaryexp(ordering,binaryexp.args[3]))
  end

  if binaryexp.args[1] == :$
    return (parsebinaryexp(ordering,binaryexp.args[2]) $
            parsebinaryexp(ordering,binaryexp.args[3]))
  end

  throw(Meta.ParseError("unknown bitwise binary operator $(binaryexp.args[1])"))
end

function parsebinaryfunct(binaryfunct::Expr)
  if binaryfunct.head == :->
    O=parseordering(binaryfunct.args[1])

    #if ordering!=nothing && ordering != O
    #  throw(ArgumentError("the parsed order $(O) and the passed order $(ordering) are not the same"))
    #end

    return parsebinaryexp(O,binaryfunct.args[2].args[2])
  end

  throw(Meta.ParseError("unknown bitwise binary function $(binaryfunct)"))
end

function OBDD(ordering::Ordering,binaryexpstr::String)
  binaryexp=Meta.parse(binaryexpstr)

  return parsebinaryexp(ordering,binaryexp)
end

function OBDD(ordering::Array{String,1},binaryexpstr::String)
  return OBDD(ListOrdering(ordering),binaryexpstr)
end

function OBDD(ordering::Array{Char,1},binaryexpstr::String)
  return OBDD(ListOrdering(ordering),binaryexpstr)
end

function OBDD(binaryfunctstr::String)
  binaryfunct=Meta.parse(binaryfunctstr)

  return parsebinaryfunct(binaryfunct)
end

function changeordering(A::OBDD,O::Ordering)
  return OBDD(O,string(A.root))
end

function changeordering(A::OBDD,O::Array{String,1})
  return changeordering(A,ListOrdering(O))
end

function changeordering(A::OBDD,O::Array{Char,1})
  return changeordering(A,ListOrdering(O))
end

function changeordering!(A::OBDD,O::Ordering)
  A.root=OBDD(O,string(A.root)).root
  A.ordering=O

  return A
end

function changeordering!(A::OBDD,O::Array{String,1})
  return changeordering!(A,ListOrdering(O))
end

function changeordering!(A::OBDD,O::Array{Char,1})
  return changeordering!(A,ListOrdering(O))
end
