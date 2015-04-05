type OBDD
  ordering::Ordering
  root::BDDNode

  function OBDD(ordering::Array{ASCIIString,1},bdd::BDDNode)
    try
      O=ListOrdering(ordering)
      return OBDD(O,bdd)
    catch e
      throw(typeof(e)(e.msg))
    end
  end

  function OBDD(O::Ordering,bdd::BDDNode)
    if !respect(bdd,O)
      throw(ArgumentError("$(bdd) does not respect $(O)"))
    end

    try
      return new(O,bdd)
    catch e
      throw(typeof(e)(e.msg))
    end
  end

  function OBDD(O::Ordering,value::Bool)
    try
      return new(O,BDD(value))
    catch e
      throw(typeof(e)(e.msg))
    end
  end
end

function string(A::OBDD)
  if typeof(A.ordering) == ListOrdering
    ordstr=string(A.ordering)
  else
    ordstr="(?)"
  end
  return string(ordstr,"->",string(A.root))
end

print(io::IO, A::OBDD) = print(io, string(A))
println(io::IO, A::OBDD) = println(io, string(A))

show(io::IO, A::OBDD) = show(io, string(A))

function variables(A::OBDD)
  return variables(A.root)
end

function ~(A::OBDD)
  return OBDD(A.ordering,~A.root)
end

function (&)(A::OBDD,B::OBDD)
  if A.ordering!=B.ordering
    throw(ArgumentError("$(A) and $(B) do not share the same ordering"))
  end

  return OBDD(A.ordering,applyoperator(((v1,v2)->v1&v2),A.root,B.root,A.ordering))
end

function (&)(a::BinBoolType,B::OBDD)
  return BDD(a)&B
end

function (&)(A::OBDD,b::BinBoolType)
  return A&BDD(b)
end

function (&)(A::OBDD,B::BDDNode)
  return A&OBDD(A.ordering,B)
end

function (&)(A::BDDNode,B::OBDD)
  return OBDD(B.ordering,A)&B
end

function (|)(A::OBDD,B::OBDD)
  if A.ordering!=B.ordering
    throw(ArgumentError("$(A) and $(B) do not share the same ordering"))
  end

  return OBDD(A.ordering,applyoperator(((v1,v2)->v1|v2),A.root,B.root,A.ordering))
end


function (|)(a::BinBoolType,B::OBDD)
  return BDD(a)|B
end

function (|)(A::OBDD,b::BinBoolType)
  return A|BDD(b)
end

function (|)(A::OBDD,B::BDDNode)
  return A|OBDD(A.ordering,B)
end

function (|)(A::BDDNode,B::OBDD)
  return OBDD(B.ordering,A)|B
end

function ==(A::OBDD,B::OBDD)
  if A.ordering!=B.ordering
    throw(ArgumentError("$(A) and $(B) do not share the same ordering"))
  end

  return A.root == B.root
end

function ==(A::OBDD,b::BDDNode)
  return A.root == b
end

function ==(a::BDDNode,B::OBDD)
  return a == B.root
end

function ==(A::OBDD,b::BinBoolType)
  return A.root == BDD(b)
end

function ==(a::BinBoolType,B::OBDD)
  return B.root == BDD(a)
end

function restrict(A::OBDD,var::ASCIIString,value)
  root=restrict(A.root,var,value)
  return OBDD(A.ordering,root)
end
