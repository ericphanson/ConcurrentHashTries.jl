module ConcurrentHashTries

export Ctrie
export lookup, insert

#####
##### Types
#####

# This is a translation of Fig. 3 of "Concurrent Tries with Efficient Non-Blocking Snapshots" by Prokopec et al


export Ctrie
export lookup, insert

#####
##### Types
#####

# This is a translation of Fig. 3 of "Concurrent Tries with Efficient Non-Blocking Snapshots" by Prokopec et al

const BITMAP = UInt32
const W = 5

mutable struct Gen end

mutable struct ParametricINode{M}
    @atomic main::M
    const gen::Gen
end

struct PackedNode{K,V}
    kind::UInt8
    key::Union{Nothing,K}
    val::Union{Nothing,V}
    next::Union{Nothing,PackedNode{K,V}}
    data::Union{Nothing,Vector{Union{ParametricINode{PackedNode{K,V}},PackedNode{K,V}}}}
    bitmap::BITMAP
end

const SNODE_KIND = UInt8(0)
const TNODE_KIND = UInt8(1)
const LNODE_KIND = UInt8(2)
const CNODE_KIND = UInt8(3)

struct SNode{K,V} end
struct TNode{K,V} end
struct LNode{K,V} end
struct CNode{K,V} end

function SNode{K,V}(key, val) where {K, V}
    return PackedNode{K,V}(SNODE_KIND, key, val, nothing, nothing, zero(BITMAP))
end

function TNode{K,V}(key, val) where {K, V}
    return PackedNode{K,V}(TNODE_KIND, key, val, nothing, nothing, zero(BITMAP))
end

function LNode{K,V}(key, val, next) where {K, V}
    return PackedNode{K,V}(LNODE_KIND, key, val, next, nothing, zero(BITMAP))
end

function CNode{K,V}(data, bitmap) where {K, V}
    return PackedNode{K,V}(CNODE_KIND, nothing, nothing, nothing, data, bitmap)
end

const INode{K,V} = ParametricINode{PackedNode{K,V}}

is_inode(x) = x isa INode
is_snode(x) = x.kind == SNODE_KIND
is_lnode(x) = x.kind == LNODE_KIND
is_tnode(x) = x.kind == TNODE_KIND
is_cnode(x) = x.kind == CNODE_KIND
const Branch{K,V} = Union{INode{K,V},PackedNode{K,V}}

const Node{K,V} = Union{INode{K,V},PackedNode{K,V}}
struct Ctrie{K,V}
    root::INode{K,V}
    readonly::Bool
end

Ctrie{K,V}() where {K,V} = Ctrie{K,V}(INode{K,V}(CNode{K,V}(Branch{K,V}[], zero(BITMAP)), Gen()), false)
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
    if is_cnode(main)
        cn = main
        flag, pos = flagpos(hash(key), lev, cn.bitmap)
        if cn.bitmap ⊙ flag == 0
            return NOTFOUND
        end
        x = cn.data[pos]
        if is_inode(x)
            in = x
            return ilookup(in, key, lev + W, i)
        elseif is_snode(x)
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
        # elseif is_tnode(main)
        # tn = main
        # clean(parent, lev - W)
        # return RESTART
    elseif is_lnode(main)
        ln = main
        return linked_list_lookup(ln, key)
    else
        error("unexpected type $(typeof(main))")
    end
end

function linked_list_lookup(ln::Node, k)
    if ln.key == k
        return ln.val
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
function updated(cn::Node{K,V}, pos, in) where {K,V}
    @assert is_cnode(cn)
    array = cn.data
    bitmap = cn.bitmap
    narr = copy(array)
    narr[pos] = in
    return CNode{K,V}(narr, bitmap)
end

# Insert `sn` to `cn` at pos
# https://github.com/scala/scala/blob/0d0d2195d7ea31f44d979748465434283c939e3b/src/library/scala/collection/concurrent/TrieMap.scala#L576C1-L585C1
function cnode_inserted(cn::Node{K,V}, pos, flag, sn) where {K,V}
    @assert is_cnode(cn)
    @assert is_snode(sn)

    arr = cn.data
    bmp = cn.bitmap | flag
    len = length(arr)
    narr = similar(arr, len + 1)

    narr[1:(pos-1)] = arr[1:(pos-1)]
    narr[pos] = sn
    narr[(pos+1):end] = arr[(pos):end]
    return CNode{K,V}(narr, bmp)
end

function lnode_inserted(ln::Node{K,V}, k, v) where {K,V}
    @assert is_lnode(ln)
    return LNode{K,V}(k,v,ln)
end

# https://github.com/scala/scala/blob/0d0d2195d7ea31f44d979748465434283c939e3b/src/library/scala/collection/concurrent/TrieMap.scala#L656
function dual(x::Node{K,V}, xhc::UInt, y::Node{K,V}, yhc::UInt, lev::Int, gen::Gen) where {K,V}
    @assert is_snode(x)
    @assert is_snode(y)
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
        return LNode{K,V}(x.key, x.val, LNode{K,V}(y.key, y.val, nothing))
    end
end

# Fig. 6: Insert operation
function iinsert(i::Node{K,V}, key, val, lev, parent) where {K,V}
    @assert is_inode(i)
    n = i.main
    hc = hash(key)
    if is_cnode(n)
        cn = n
        flag, pos = flagpos(hc, lev, cn.bitmap)
        if cn.bitmap ⊙ flag == 0
            ncn = cnode_inserted(cn, pos, flag, SNode{K,V}(key, val))
            _, cas_suceeded = @atomicreplace i.main cn => ncn
            if cas_suceeded
                return OK
            else
                return RESTART
            end
        end
        x = cn.data[pos]
        if is_inode(x)
            sin = x
            return iinsert(sin, key, val, lev + W, i)
        elseif is_snode(x)
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
        # elseif is_tnode(n)
        # clean(parent, lev - W)
        # return RESTART
    elseif is_lnode(n)
        ln = n
        nln = lnode_inserted(ln, key, val)
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
