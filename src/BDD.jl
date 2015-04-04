abstract BDDNode

type BDDTerminal <: BDDNode
  value::Bool
  f_low::Union(Set{BDDNode},Nothing)
  f_high::Union(Set{BDDNode},Nothing)

  Tnodes::Dict{Bool,BDDTerminal} = Dict()
  function BDDTerminal(value::Bool)
    if !haskey(Tnodes,value)
      Tnodes[value]=new(value,Set{BDDNode}(),Set{BDDNode}())
    end

    return Tnodes[value]
  end
end

function isdestroyed(A::BDDNode)
  return A.f_low==nothing || A.f_high==nothing
end

function destroy!(A::BDDNode)
  if isdestroyed(A)
    return
  end

  for father in A.f_low|A.f_high
    destroy!(father)
  end

  A.f_low=nothing
  A.f_high=nothing
end

function invert!(a::BDDTerminal,result_cache=Dict())
  if a in result_cache
    return result_cache[a]
  end

  result_cache[a]=BDD(!a.value)

  return result_cache[a]
end

function ~(a::BDDNode)
  return invert!(a,Dict())
end

function string(a::BDDTerminal)
  return "$(a.value)"
end

type BDDNonTerminal <: BDDNode
  var::ASCIIString
  low::BDDNode
  high::BDDNode
  f_low::Set{BDDNode}
  f_high::Set{BDDNode}

  function BDDNonTerminal(var::ASCIIString,low::BDDNode,high::BDDNode)
    if low===high
      return low
    end

    if length(high.f_high)>length(low.f_low)
      nodeSet=low.f_low
      test=(node->node.high===high)
    else
      nodeSet=high.f_high
      test=(node->node.low===low)
    end

    for node in nodeSet
      if typeof(node)==BDDNonTerminal && node.var==var && test(node)
        return node
      end
    end
    node=new(var,low,high,Set{BDDNode}(),Set{BDDNode}())

    push!(high.f_high,node)
    push!(low.f_low,node)

    return node
  end
end

function destroy!(A::BDDNonTerminal)
  if isdestroyed(A)
    return
  end

  for father in A.f_low|A.f_high
    destroy!(father)
  end

  A.f_low=nothing
  A.f_high=nothing

  A.low.f_low
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
  repr=ASCIIString[]

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

function BDD(value::Bool)
  return BDDTerminal(value)
end

function BDD(var::ASCIIString,low::BDDNode,high::BDDNode)
  return BDDNonTerminal(var,low,high)
end

function respect!(bdd::BDDNode,O::Ordering,checked::Set)
  if in(bdd,checked)
    return true
  end

  if typeof(bdd)==BDDTerminal
    push!(checked,bdd)

    return true
  end

  if typeof(bdd)==BDDNonTerminal
    if !in(bdd.var,O)
      throw(ArgumentError("$(bdd.var) is not in $(O)"))
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
  if isdestroyed(A)
    throw(ArgumentError("This BDDNode has been destroyed"))
  end

  anc=Set{BDDNode}()
  stack=BDDNode[A]

  while !isempty(stack)
    node=pop!(stack)

    if !in(node,anc)&&!in(node,checked)
      push!(anc,node)

      for father in union(node.f_low,node.f_high)
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
  if isdestroyed(A)
    throw(ArgumentError("This BDDNode has been destroyed"))
  end

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

function BDDgarbagecollect(exceptions)
  to_be_saved=Set{BDDNode}()

  for node in exceptions
    if typeof(node)==BDDNode
      to_be_saved=union(to_be_saved,descendents(node,to_be_saved))
    end
  end

  to_be_removed=ancestors(BDDNode(True),to_be_saved)
  to_be_removed=ancestors(BDDNode(False),union(to_be_removed,to_be_saved))

  for node in setdiff(to_be_removed,to_be_saved)
    destroy!(node)
  end
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

function applyoperator!(operator,A::BDDNode,B::BDDNode,O::Ordering,result_cache::Dict)
  if !haskey(result_cache,A)
    result_cache[A]=Dict()
  end

  if haskey(result_cache[A],B)
    return result_cache[A][B]
  end

  result_cache[A][B]=compute!(operator,A,B,O,result_cache)

  return result_cache[A][B]
end

function applyoperator(operator,A::BDDNode,B::BDDNode,O::Ordering)
  return applyoperator!(operator,A,B,O,Dict())
end

function compute!(operator,A::BDDNode,B::BDDNode, O::Ordering,result_cache::Dict)
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

function compute(operator,A::BDDNode,B::BDDNode, O::Ordering)
  return compute!(operator,A,B,O,Dict())
end

function restrict(A::BDDNode,var::ASCIIString,value::Integer)
  if value==0
    return restrict(A,var,false)
  end

  if value==1
    return restrict(A,var,true)
  end

  throw(ArgumentError("expected a binary value, got $(value)"))
end

function restrict!(A::BDDNode,var::ASCIIString,value::Bool,result_cache::Dict)
  if haskey(result_cache,A)
    return result_cache[A]
  end

  result_cache[A]=computerestriction!(A,var,value,result_cache)

  return result_cache[A]
end

function restrict(A::BDDNode,var::ASCIIString,value::Bool)
  return restrict!(A,var,value,Dict())
end

function computerestriction!(A::BDDNode,var::ASCIIString,value::Bool,result_cache::Dict)
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
