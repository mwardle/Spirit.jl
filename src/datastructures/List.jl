abstract type List{T} end

struct Nil{T} <: List{T} end

function Nil(T::Type)
    Nil{T}()
end

struct Cons{T} <: List{T}
    head::T
    tail::List{T}
end

function Cons{T}(entry::T)
    Cons{T}(entry, Nil{T}())
end

function List{T}(entries::T...)
    list = Nil{T}()
    for entry in reverse(entries)
        list = Cons{T}(entry, list)
    end
    list
end

function List{T}() where T
    Nil{T}()
end

function Base.show(io::IO, list::Nil{T}) where {T}
    print(io, "List{", T ,"}()")
end

function Base.show(io::IO, list::Cons{T}) where {T}
    print(io, "List{", T ,"}(")
    show(io, list.head)
    for entry in list.tail
        print(io, ", ")
        show(io, entry)
    end
    print(io, ")")
end

Base.start(list::Nil{T}) where {T} = list
Base.start(list::Cons{T}) where {T} = list
Base.done(list::List{T}, state::Nil{T}) where {T} = true
Base.done(list::List{T}, state::Cons{T}) where {T} = false
Base.next(list::Cons{T}, state::Cons{T}) where {T} = (state.head, state.tail)

Base.length(list::Nil{T}) where {T} = 0
Base.length(list::Cons{T}) where {T} = 1 + Base.length(list.tail)

Base.eltype(list::List{T}) where {T} = T
Base.eltype(::Type{List{T}}) where {T} = T

Base.isempty(list::Nil{T}) where {T} = true
Base.isempty(list::Cons{T}) where {T} = false

Base.endof(list::List{T}) where {T} = Base.length(list)

Base.in(item, list::Nil{T}) where T = false
Base.in(item, list::Cons{T}) where T = list.head == item || Base.in(item, list.tail)

Base.map(fn::Function, list::Nil{T}) where T = list
Base.map(fn::Function, list::Cons{T}) where T = Cons(fn(list.head), Base.map(fn, list.tail))

Base.filter(fn::Function, list::Nil{T}) where T = list
Base.filter(fn::Function, list::Cons{T}) where T = 
    if fn(list.head) 
        Cons(list.head, Base.filter(fn, list.tail)) 
    else
        Base.filter(fn, list.tail)
    end

Base.getindex(list::Nil{T}, index::Integer) where T = throw(BoundsError(list, index))
Base.getindex(list::Cons{T}, index::Integer) where T =
    if index == 1
        list.head
    else 
        try
            Base.getindex(list.tail, index - 1)
        catch err
            if isa(err, BoundsError)
                throw(BoundsError(list, index))
            else
                throw(err)
            end
        end
    end