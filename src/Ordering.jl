abstract type Ordering end

mutable struct ListOrdering <: Ordering
  ordering::Dict
  length::Integer

  function ListOrdering(ordering::Vector{String})
    O=Dict()
    i=1
    for var in ordering
      if haskey(O,var)
        throw(ArgumentError("$(var) appears twice in $(ordering)"))
      end
      O[var]=i
      i=i+1
    end

    return new(O,i-1)
  end

  function ListOrdering(ordering::Array{Char,1};dynamic=false)
    varnames=String[]

    for char in ordering
      push!(varnames,string(char))
    end

    return ListOrdering(varnames)
  end
end

global dynamicOBDDordering=false

function set_dynamic_ordering()
  global dynamicOBDDordering

  dynamicOBDDordering=true

  return "Dynamic variable ordering has been enabled"
end

function set_static_ordering()
  global dynamicOBDDordering

  dynamicOBDDordering=false

  return "Dynamic variable ordering has been disabled"
end

function addgreatest!(O::ListOrdering,var::String)
  global dynamicOBDDordering

  if !dynamicOBDDordering
    throw(ArgumentError("dynamicOBDDordering is set to false: ListOrdering cannot be changed!"))
  end

  if (haskey(O,var))
    throw(ArgumentError("$(O) already contains $(var)"))
  end

  O.length+=1
  O.ordering[var]=O.length
end

function convert(::Type{Array{String,1}},O::ListOrdering)
  return sort!(String[key for key in keys(O.ordering)],
               lt=((a,b)->inorder(O,a,b)))
end

function variablesin(O::ListOrdering)
  return Set{String}(keys(O.ordering))
end

function in(var::String,O::ListOrdering)
  return haskey(O.ordering,var)
end

function haskey(O::ListOrdering,a::String)
  return haskey(O.ordering,a)
end

function inorder(O::ListOrdering,a::String,b::String)
  for var in [a,b]
    if !haskey(O,var)
      throw(ArgumentError("$(var) is not in $(O)"))
    end
  end

  return O.ordering[a]<O.ordering[b]
end

function ==(A::ListOrdering,B::ListOrdering)
  return A.ordering==B.ordering
end

function !=(A::ListOrdering,B::ListOrdering)
  return !(A==B)
end

function string(A::ListOrdering)
  str="("
  sep=""
  for var in convert(Array{String,1},A)
    str=string(str,sep,var)
    sep=","
  end
  return string(str,")")
end

function definedfor(A::ListOrdering, B::Set{String})
  try
    for var in B
      if !in(var,A)
        return false
      end
    end
  catch e
    return false
  end

  return true
end

function merge(A::ListOrdering, B::ListOrdering)
  #this should be replaced by a topological sort on the
  #ordering graph.

  ordering=convert(Array{String,1},A)

  BnotinA=setdiff(variablesin(B),variablesin(A))
  for var in convert(Array{String,1},B)
    if var in BnotinA
      push!(ordering,var)
    end
  end

  return ListOrdering(ordering)
end

print(io::IO, A::ListOrdering) = print(io, string(A))
println(io::IO, A::ListOrdering) = println(io, string(A))

show(io::IO, A::ListOrdering) = show(io, string(A))
