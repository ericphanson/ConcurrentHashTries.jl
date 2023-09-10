module ConcurrentHashTries

export Ctrie
export lookup, insert

#####
##### Types
#####

# This is a translation of Fig. 3 of "Concurrent Tries with Efficient Non-Blocking Snapshots" by Prokopec et al

# Using an abstract type instead of a union, since
# julia doesn't have mutually recursive types, xref
# https://github.com/JuliaLang/julia/issues/269
abstract type Branch{K,V} end

const BITMAP = UInt32
const W = 5

struct Gen end

struct SNode{K,V} <: Branch{K,V}
    key::K
    val::V
end

struct TNode{K,V}
    sn::SNode{K,V}
end

struct LNode{K,V}
    sn::SNode{K,V}
    next::Union{Nothing,LNode{K,V}}
end

# This is analogous to HMAT{K,V} from https://github.com/vchuravy/HashArrayMappedTries.jl,
# except we allow INode's in the vector too.
struct CNode{K,V}
    data::Vector{Branch{K,V}}
    bitmap::BITMAP
end

CNode{K,V}() where {K,V} = CNode(Vector{Branch{K,V}}(undef, 0), zero(BITMAP))

MainNode{K,V} = Union{CNode{K,V},TNode{K,V},LNode{K,V}}

mutable struct INode{K,V} <: Branch{K,V}
    @atomic main::MainNode{K,V}
    const gen::Gen
end

struct Ctrie{K,V}
    root::INode{K,V}
    readonly::Bool
end

Ctrie{K,V}() where {K,V} = Ctrie{K,V}(INode{K,V}(CNode{K,V}(), Gen()), false)
Ctrie() = Ctrie{Any,Any}()

#####
##### Notation
#####

@enum State RESTART NOTFOUND OK

const null = nothing
const ⊙ = &

# https://github.com/scala/scala/blob/0d0d2195d7ea31f44d979748465434283c939e3b/src/library/scala/collection/concurrent/TrieMap.scala#L111-L115
function flagpos(hc::UInt, lev, bmp)
    idx = (hc >>> UInt32(lev)) & 0x1f
    flag = (UInt32(1) << idx)
    mask = flag - UInt32(1)
    pos = count_ones(bmp & mask) + 1
    return flag, pos
end

#####
##### Lookup
#####

# Fig. 4: lookup operation
function lookup(c::Ctrie, k)
    r = c.root
    res = ilookup(r, k, 0, null)
    if res ≠ RESTART
        return res
    else
        return lookup(c, k)
    end
end

# Fig. 4: lookup operation
function ilookup(i::INode, key, lev, parent)
    main = i.main
    if main isa CNode
        cn = main
        flag, pos = flagpos(hash(key), lev, cn.bitmap)
        if cn.bitmap ⊙ flag == 0
            return NOTFOUND
        end
        x = cn.data[pos]
        if x isa INode
            in = x
            return ilookup(in, key, lev + W, i)
        elseif x isa SNode
            sn = x
            if sn.key == key
                return sn.val
            else
                return NOTFOUND
            end
        else
            error("unexpected type $(typeof(x))")
        end
        # Uncomment once `clean` is implemented as part of compression
        # elseif main isa TNode
        # tn = main
        # clean(parent, lev - W)
        # return RESTART
    elseif main isa LNode
        ln = main
        return linked_list_lookup(ln, key)
    else
        error("unexpected type $(typeof(main))")
    end
end

function linked_list_lookup(ln::LNode, k)
    if ln.sn.key == k
        return ln.sn.val
    elseif ln.next === nothing
        return NOTFOUND
    else
        linked_list_lookup(ln.next, k)
    end
end

#####
##### Insert
#####

# Fig. 6: Insert operation
function insert(c::Ctrie, k, v)
    r = c.root
    if iinsert(r, k, v, 0, null) == RESTART
        insert(c, k, v)
    end
    return nothing
end

# Update `pos` to have this INode
# https://github.com/scala/scala/blob/0d0d2195d7ea31f44d979748465434283c939e3b/src/library/scala/collection/concurrent/TrieMap.scala#L559-L565
function updated(cn::CNode{K,V}, pos, in) where {K,V}
    array = cn.data
    bitmap = cn.bitmap
    narr = copy(array)
    narr[pos] = in
    return CNode{K,V}(narr, bitmap)
end

# Insert `sn` to `cn` at pos
# https://github.com/scala/scala/blob/0d0d2195d7ea31f44d979748465434283c939e3b/src/library/scala/collection/concurrent/TrieMap.scala#L576C1-L585C1
function inserted(cn::CNode{K,V}, pos, flag, sn::SNode) where {K,V}
    arr = cn.data
    bmp = cn.bitmap | flag
    len = length(arr)
    narr = similar(arr, len + 1)

    narr[1:(pos-1)] = arr[1:(pos-1)]
    narr[pos] = sn
    narr[(pos+1):end] = arr[(pos):end]
    return CNode{K,V}(narr, bmp)
end

function inserted(ln::LNode{K,V}, k, v) where {K,V}
    return LNode{K,V}(SNode{K,V}(k, v), ln)
end

# https://github.com/scala/scala/blob/0d0d2195d7ea31f44d979748465434283c939e3b/src/library/scala/collection/concurrent/TrieMap.scala#L656
function dual(x::SNode{K,V}, xhc::UInt, y::SNode{K,V}, yhc::UInt, lev::Int, gen::Gen) where {K,V}
    if lev < 35 # why 35
        xidx = (xhc >>> UInt32(lev)) & 0x1f
        yidx = (yhc >>> UInt32(lev)) & 0x1f
        bmp = (UInt32(1) << xidx) | (UInt32(1) << yidx)
        if xidx == yidx
            mainnode = dual(x, xhc, y, yhc, lev + 5, gen)
            subinode = INode{K,V}(mainnode, gen)
            return CNode{K,V}(Branch{K,V}[subinode], bmp)
        else
            if xidx < yidx
                return CNode{K,V}(Branch{K,V}[x, y], bmp)
            else
                return CNode{K,V}(Branch{K,V}[y, x], bmp)
            end
        end
    else
        # Linked list of x and y
        return LNode{K,V}(x, LNode{K,V}(y, nothing))
    end
end

# Fig. 6: Insert operation
function iinsert(i::INode{K,V}, key, val, lev, parent) where {K,V}
    n = i.main
    hc = hash(key)
    if n isa CNode
        cn = n
        flag, pos = flagpos(hc, lev, cn.bitmap)
        if cn.bitmap ⊙ flag == 0
            ncn = inserted(cn, pos, flag, SNode{K,V}(key, val))
            _, cas_suceeded = @atomicreplace i.main cn => ncn
            if cas_suceeded
                return OK
            else
                return RESTART
            end
        end
        x = cn.data[pos]
        if x isa INode
            sin = x
            return iinsert(sin, key, val, lev + W, i)
        elseif x isa SNode
            sn = x
            if !isequal(sn.key, key)
                nsn = SNode{K,V}(key, val)

                # TODO: which gen
                gen = Gen()
                inner_c = dual(sn, hash(sn.key), nsn, hc, lev + 5, gen)
                nin = INode{K,V}(inner_c, gen)
                ncn = updated(cn, pos, nin)
                _, cas_suceeded = @atomicreplace i.main cn => ncn
                if cas_suceeded
                    return OK
                else
                    return RESTART
                end
            else
                ncn = updated(cn, pos, SNode{K,V}(key, val))
                _, cas_suceeded = @atomicreplace i.main cn => ncn
                if cas_suceeded
                    return OK
                else
                    return RESTART
                end
            end
        end
        # Uncomment once `clean` is implemented as part of compression
        # elseif n isa TNode
        # clean(parent, lev - W)
        # return RESTART
    elseif n isa LNode
        ln = n
        nln = inserted(ln, key, val)
        _, cas_suceeded = @atomicreplace i.main ln => nln
        if cas_suceeded
            return OK
        else
            return RESTART
        end
    else
        error("unexpected type $(typeof(n))")
    end

end

end # module
