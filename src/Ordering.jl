abstract Ordering

type ListOrdering <: Ordering
  ordering::Dict

  function ListOrdering(ordering::Array{ASCIIString,1})
    O=Dict()
    i=1
    for var in ordering
      if haskey(O,var)
        throw(ArgumentError("$(var) appears twice in $(ordering)"))
      end
      O[var]=i
      i=i+1
    end

    try
      return new(O)
    catch e
      throw(typeof(e)(e.msg))
    end

  end

  function ListOrdering(ordering::Array{Char,1})
    varnames=ASCIIString[]

    for char in ordering
      push!(varnames,string(char))
    end

    return ListOrdering(varnames)
  end
end

function convert(::Type{Array{ASCIIString,1}},O::Ordering)
  return sort!(ASCIIString[key for key in keys(O.ordering)],lt=((a,b)->inorder(O,a,b)))
end

function in(var::ASCIIString,O::ListOrdering)
  return haskey(O.ordering,var)
end

function haskey(O::ListOrdering,a::ASCIIString)
  return haskey(O.ordering,a)
end

function inorder(O::ListOrdering,a::ASCIIString,b::ASCIIString)
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
  for var in convert(Array{ASCIIString,1},A)
    str=string(str,sep,var)
    sep=","
  end
  return string(str,")")
end


print(io::IO, A::ListOrdering) = print(io, string(A))
println(io::IO, A::ListOrdering) = println(io, string(A))

show(io::IO, A::ListOrdering) = show(io, string(A))
