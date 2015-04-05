function parseboolexp(ordering::Ordering,value::BinBoolType)
  return OBDD(ordering,value)
end

function parseboolexp(ordering::Ordering,var::Symbol)
  return OBDD(ordering,BDD(string(var),BDD(false),BDD(true)))
end

function parseordering(ordering::Expr)
  if ordering.head != :tuple
    throw(ParseError("expected a tuple, got $(ordering)"))
  end

  return ListOrdering(ASCIIString[string(var) for var in ordering.args])
end

function parseboolexp(ordering::Ordering,boolexp::Expr)
  if boolexp.head == :&&
    return parseboolexp(ordering,boolexp.args[1])&parseboolexp(ordering,boolexp.args[1])
  end

  if boolexp.head == :||
    return parseboolexp(ordering,boolexp.args[1])&parseboolexp(ordering,boolexp.args[1])
  end

  if boolexp.head != :call
    throw(ParseError("expected a boolean operator, got $(boolexp.head)"))
  end

  if boolexp.args[1] == :~ || boolexp.args[1] == :!
    return ~parseboolexp(ordering,boolexp.args[2])
  end

  if boolexp.args[1] == :&
    return parseboolexp(ordering,boolexp.args[2])&parseboolexp(ordering,boolexp.args[3])
  end

  if boolexp.args[1] == :|
    return parseboolexp(ordering,boolexp.args[2])|parseboolexp(ordering,boolexp.args[3])
  end

  throw(ParseError("unknown boolean operator $(boolexp.args[1])"))
end

function parseboolfunct(boolfunct::Expr)
  if boolfunct.head == :->
    O=parseordering(boolfunct.args[1])

    #if ordering!=nothing && ordering != O
    #  throw(ArgumentError("the parsed order $(O) and the passed order $(ordering) are not the same"))
    #end

    return parseboolexp(O,boolfunct.args[2].args[2])
  end

  throw(ParseError("unknown boolean function $(boolfunct)"))
end

function OBDD(ordering::Ordering,boolexpstr::ASCIIString)
  try
    boolexp=parse(boolexpstr)

    return parseboolexp(ordering,boolexp)
  catch e
    throw(typeof(e)(e.msg))
  end
end

function OBDD(ordering::Array{ASCIIString,1},boolexpstr::ASCIIString)
  try
    return OBDD(ListOrdering(ordering),boolexpstr)
  catch e
    throw(typeof(e)(e.msg))
  end
end

function OBDD(ordering::Array{Char,1},boolexpstr::ASCIIString)
  try
    return OBDD(ListOrdering(ordering),boolexpstr)
  catch e
    throw(typeof(e)(e.msg))
  end
end

function OBDD(boolfunctstr::ASCIIString)
  try
    boolfunct=parse(boolfunctstr)

    return parseboolfunct(boolfunct)
  catch e
    throw(typeof(e)(e.msg))
  end
end
