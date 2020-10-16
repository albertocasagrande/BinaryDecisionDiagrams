abstract type BDDNode end

const BinBoolType = Union{Integer,Bool}

struct BDDTerminal <: BDDNode
  value::Bool
  f_low::WeakKeyDict{BDDNode,Bool}
  f_high::WeakKeyDict{BDDNode,Bool}

  function BDDTerminal(value::BinBoolType)
    if value==0 || value==false
      value=0
    elseif value==1 || value==true
      value=1
    else
      throw(ArgumentError("expected a binary value, got $(value)"))
    end

    if !haskey(Tnodes,value)
      Tnodes[value]=new(value,WeakKeyDict{BDDNode,Bool}(),
                              WeakKeyDict{BDDNode,Bool}())
    end

    return Tnodes[value]
  end
end

const Tnodes = Dict{Bool,BDDTerminal}()

function invert!(a::BDDTerminal,result_cache=Dict())
  if a in keys(result_cache)
    return result_cache[a]
  end

  result_cache[a]=BDD(!a.value)

  return result_cache[a]
end

function ~(a::BDDNode)
  return invert!(a,Dict())
end

function string(a::BDDTerminal)
  if a.value
    return "1"
  else
    return "0"
  end
end

mutable struct BDDNonTerminal <: BDDNode
  var::String
  low::BDDNode
  high::BDDNode
  f_low::WeakKeyDict{BDDNode,Bool}
  f_high::WeakKeyDict{BDDNode,Bool}

  function BDDNonTerminal(var::String,low::BDDNode,high::BDDNode)
    if low===high
      return low
    end

    if length(high.f_high)>length(low.f_low)
      nodeDict=low.f_low
      test=(node->node.high===high)
    else
      nodeDict=high.f_high
      test=(node->node.low===low)
    end

    for node in keys(nodeDict)
      if node.var==var && test(node)
        return node
      end
    end
    node=new(var,low,high,WeakKeyDict{BDDNode,Bool}(),
                          WeakKeyDict{BDDNode,Bool}())

    high.f_high[node]=true
    low.f_low[node]=true

    return node
  end
end


function SAT_assignments!(A::Array{Dict{String, BinBoolType}}, 
                          tmp_a::Dict{String, BinBoolType}, 
                          node::BDDNode)
  if typeof(node)==BDDTerminal
    if node.value==true || node.value==1
      push!(A, copy(tmp_a))
    end
  else
    tmp_a[node.var] = 0
    SAT_assignments!(A, tmp_a, node.low)
  
    tmp_a[node.var] = 1
    SAT_assignments!(A, tmp_a, node.high)
  
    delete!(tmp_a, node.var)
  end 
end

function SAT_assignments(node::BDDNode)::Array{Dict{String, BinBoolType}}
  tmp_a = Dict{String, BinBoolType}()
  A = Dict{String, BinBoolType}[]
  
  SAT_assignments!(A, tmp_a, node)

  return A
end

function invert!(a::BDDNonTerminal,result_cache=Dict())
  if haskey(result_cache,a)
    return result_cache[a]
  end

  result_cache[a]=BDDNonTerminal(a.var,
                                 invert!(a.low,result_cache),
                                 invert!(a.high,result_cache))

  return result_cache[a]
end

function string(a::BDDNonTerminal)
  repr=String[]

  if typeof(a.low)==BDDTerminal
    if a.low.value
      push!(repr,"~$(a.var)")
    end
  else
    push!(repr,"(~$(a.var) & $(a.low))")
  end

  if typeof(a.high)==BDDTerminal
    if a.high.value
      push!(repr,"$(a.var)")
    end
  else
    push!(repr,"($(a.var) & $(a.high))")
  end

  if length(repr)==2
    return "($(repr[1]) | $(repr[2]))"
  end

  return repr[1]
end

print(io::IO, x::BDDNode) = print(io, string(x))
println(io::IO, x::BDDNode) = println(io, string(x))

show(io::IO, x::BDDNode) = show(io, "$(string(x))")

==(a::BDDNode,b::BDDNode) = (a === b)

==(a::BDDNode,b::BinBoolType) = (a === BDD(b))

==(a::BinBoolType,b::BDDNode) = (BDD(a) === b)

function BDD(value::BinBoolType)
  return BDDTerminal(value)
end

function BDD(var::String,low::BDDNode,high::BDDNode)
  return BDDNonTerminal(var,low,high)
end

function respect!(bdd::BDDNode,O::Ordering,checked::Set)
  global dynamicOBDDordering

  if in(bdd,checked)
    return true
  end

  if typeof(bdd)==BDDTerminal
    push!(checked,bdd)

    return true
  end

  if typeof(bdd)==BDDNonTerminal
    if !in(bdd.var,O)
      if dynamicOBDDordering

      else
        throw(ArgumentError("$(bdd.var) is not in $(O)"))
      end
    end

    for son in BDDNode[bdd.low,bdd.high]
      if typeof(son) == BDDNonTerminal && !inorder(O,bdd.var,son.var)
        return false
      end
    end

    if (respect!(bdd.low,O,checked) && respect!(bdd.high,O,checked))
      push!(checked,bdd)

      return true
    else
      return false
    end
  end
end

function respect(bdd::BDDNode,O::Ordering)
  return respect!(bdd,O,Set{BDDNode}())
end

function ancestors!(A::BDDNode,checked::Set{BDDNode})
  anc=Set{BDDNode}()
  stack=BDDNode[A]

  while !isempty(stack)
    node=pop!(stack)

    if !in(node,anc)&&!in(node,checked)
      push!(anc,node)

      for father in union(keys(node.f_low),keys(node.f_high))
        push!(stack,father)
      end
    end
  end

  return anc
end

function ancestors(A::BDDNode)
  return ancestors!(A,Set{BDDNode}())
end

function descendents!(A::BDDNode,checked)
  desc=Set{BDDNode}()
  to_visit=BDDNode[A]

  while !isempty(to_visit)
    node=pop!(to_visit)

    if !in(node,desc)
      push!(desc,node)

      if typeof(node)==BDDNonTerminal
        push!(to_visit,node.low)
        push!(to_visit,node.high)
      end
    end
  end

  return desc
end

function descendents(A::BDDNode)
  return descendents!(A,Set{BDDNode}())
end

function variables(A::BDDNode)
  vars=Set{String}()
  for node in descendents(A)
    if typeof(node)==BDDNonTerminal
      push!(vars,node.var)
    end
  end

  return vars
end

function applyoperator!(operator::Function,A::BDDNode,B::BDDNode,O::Ordering,result_cache::Dict)
  if !haskey(result_cache,A)
    result_cache[A]=Dict()
  end

  if haskey(result_cache[A],B)
    return result_cache[A][B]
  end

  result_cache[A][B]=compute!(operator,A,B,O,result_cache)

  return result_cache[A][B]
end

function applyoperator(operator::Function,A::BDDNode,B::BDDNode,O::Ordering)
  return applyoperator!(operator,A,B,O,Dict())
end

function compute!(operator::Function,A::BDDNode,B::BDDNode, O::Ordering,result_cache::Dict)
  if typeof(A)==BDDTerminal
    if typeof(B)==BDDTerminal
      return BDD(operator(A.value,B.value))
    end
    low=applyoperator!(operator,A,B.low,O,result_cache)
    high=applyoperator!(operator,A,B.high,O,result_cache)
    return BDD(B.var,low,high)
  end

  if typeof(B)==BDDTerminal || inorder(O,A.var,B.var)
    low=applyoperator!(operator,A.low,B,O,result_cache)
    high=applyoperator!(operator,A.high,B,O,result_cache)
    return BDD(A.var,low,high)
  end

  if A.var==B.var
    low=applyoperator!(operator,A.low,B.low,O,result_cache)
    high=applyoperator!(operator,A.high,B.high,O,result_cache)

    return BDD(A.var,low,high)
  end

  if inorder(O,B.var,A.var)
    low=applyoperator!(operator,A,B.low,O,result_cache)
    high=applyoperator!(operator,A,B.high,O,result_cache)
    return BDD(B.var,low,high)
  end

  throw(ArgumentError("Unsupported configuration $(A) $(B)"))
end

function compute(operator::Function,A::BDDNode,B::BDDNode, O::Ordering)
  return compute!(operator,A,B,O,Dict())
end

function restrict(A::BDDNode,var::String,value::Integer)
  if value==0
    return restrict(A,var,false)
  end

  if value==1
    return restrict(A,var,true)
  end

  throw(ArgumentError("expected a binary value, got $(value)"))
end

function restrict!(A::BDDNode,var::String,value::Bool,result_cache::Dict)
  if haskey(result_cache,A)
    return result_cache[A]
  end

  result_cache[A]=computerestriction!(A,var,value,result_cache)

  return result_cache[A]
end

function restrict(A::BDDNode, assignment::Dict{String})
   new_node = A

   for (var, value) in assignment
      new_node = restrict(new_node, var, value)
   end

   return new_node
end

function restrict(A::BDDNode,var::String,value::Bool)
  return restrict!(A,var,value,Dict())
end

function computerestriction!(A::BDDNode,var::String,value::Bool,
                             result_cache::Dict)
  if typeof(A)==BDDTerminal
    return A
  end

  if A.var==var
    if value
      return restrict!(A.high,var,value,result_cache)
    else
      return restrict!(A.low,var,value,result_cache)
    end
  else
    low=restrict!(A.low,var,value,result_cache)
    high=restrict!(A.high,var,value,result_cache)

    return BDD(A.var,low,high)
  end
end
