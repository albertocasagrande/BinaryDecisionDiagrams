struct OBDD
  ordering::Ordering
  root::BDDNode

  function OBDD(ordering::Array{String,1},bdd::BDDNode)
    try
      O=ListOrdering(ordering)
      return OBDD(O,bdd)
    catch e
      throw(typeof(e)(e.msg))
    end
  end

  function OBDD(O::Ordering,bdd::BDDNode)
    global dynamicOBDDordering

    if !respect(bdd,O)
      if dynamicOBDDordering
        return OBDD(O,string(bdd))
      else
        throw(ArgumentError("$(bdd) does not respect $(O)"))
      end
    end

    try
      return new(O,bdd)
    catch e
      throw(typeof(e)(e.msg))
    end
  end

  function OBDD(O::Ordering,value::BinBoolType)
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

function mergeordering(A::OBDD,B::OBDD)
  if definedfor(A.ordering,variablesin(B.ordering))
    B=changeordering(B,A.ordering)
    return (A,B)
  end

  if definedfor(B.ordering,variablesin(A.ordering))
    A=changeordering(A,B.ordering)
    return (A,B)
  end

  new_ordering=merge(A.ordering,B.ordering)

  A=changeordering(A,new_ordering)
  B=changeordering(B,new_ordering)

  return (A,B)
end

function applyoperator(operator::Function,A::OBDD,B::OBDD)
  global dynamicOBDDordering

  if A.ordering!=B.ordering
    if dynamicOBDDordering
      (A,B)=mergeordering(A,B)
    else
      throw(ArgumentError("$(A) and $(B) do not share the same ordering"))
    end
  end

  return OBDD(A.ordering,applyoperator(operator,A.root,B.root,A.ordering))
end

function applyoperator(operator::Function,a::BinBoolType,B::OBDD)
  return applyoperator(operator,BDD(a),B)
end

function applyoperator(operator::Function,A::OBDD,b::BinBoolType)
  return applyoperator(operator,A,BDD(b))
end

function applyoperator(operator::Function,A::OBDD,B::BDDNode)
  return applyoperator(operator,A,OBDD(A.ordering,B))
end

function applyoperator(operator::Function,A::BDDNode,B::OBDD)
  return applyoperator(operator,OBDD(B.ordering,A),B)
end

function (&)(A::OBDD,B::OBDD)
  return applyoperator(((v1,v2)->v1&v2),A,B)
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
  return applyoperator(((v1,v2)->v1|v2),A,B)
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

function Base.xor(A::OBDD,B::OBDD)
  return applyoperator(((v1,v2)->v1 ⊻ v2),A,B)
end

function Base.xor(a::BinBoolType,B::OBDD)
  return BDD(a) ⊻ B
end

function Base.xor(A::OBDD,b::BinBoolType)
  return A ⊻ BDD(b)
end

function Base.xor(A::OBDD,B::BDDNode)
  return A ⊻ OBDD(A.ordering,B)
end

function Base.xor(A::BDDNode,B::OBDD)
  return OBDD(B.ordering,A) ⊻ B
end

function ==(A::OBDD,B::OBDD)
  global dynamicOBDDordering

  if A.ordering!=B.ordering
    if dynamicOBDDordering
      (A,B)=mergeordering(A,B)
    else
      throw(ArgumentError("$(A) and $(B) do not share the same ordering"))
    end
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

function restrict(A::OBDD,var::String,value)
  root=restrict(A.root,var,value)
  return OBDD(A.ordering,root)
end
