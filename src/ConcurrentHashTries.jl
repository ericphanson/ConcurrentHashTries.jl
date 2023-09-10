module ConcurrentHashTries

export Ctrie
export lookup, insert

using SumTypes

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

@sum_type Node{K,V} begin
    SNode{K,V}(key::K, val::V)
    TNode{K,V}(sn::Node{K,V})
    LNode{K,V}(sn::Node{K,V}, next::Union{Nothing,Node{K,V}})
    CNode{K,V}(data::Vector{Union{ParametricINode{Node{K,V}},Node{K,V}}}, bitmap::BITMAP)
end

const INode{K,V} = ParametricINode{Node{K,V}}

const Branch{K,V} = Union{INode{K,V},Node{K,V}}

CNode{K,V}() where {K,V} = CNode(Branch{K,V}[], zero(BITMAP))

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
    @cases main begin
        CNode(data, bitmap) => begin
            cn = main
            flag, pos = flagpos(hash(key), lev, bitmap)
            if bitmap ⊙ flag == 0
                return NOTFOUND
            end
            x = data[pos]
            if x isa INode
                in = x
                return ilookup(in, key, lev + W, i)
            end
            @cases x begin
                SNode(sk, sv) => begin
                    if sk == key
                        return sv
                    else
                        return NOTFOUND
                    end
                end
                TNode => error("unexpected type $(typeof(x))")
                LNode => error("unexpected type $(typeof(x))")
                CNode => error("unexpected type $(typeof(x))")
            end
        end
        # Uncomment once `clean` is implemented as part of compression
        TNode => begin
            tn = main
            clean(parent, lev - W)
            return RESTART
        end
        LNode => begin
            ln = main
            return linked_list_lookup(ln, key)
        end
        SNode => error("unexpected $(main)")
    end
end

function linked_list_lookup(ln::Node, k)
    @cases ln begin
        LNode(sn, next) => begin
            @cases sn begin
                SNode(key, val) => begin
                    if key == k
                        return val
                    elseif next === nothing
                        return NOTFOUND
                    else
                        linked_list_lookup(next, k)
                    end
                end
                TNode => error()
                LNode => error()
                CNode => error()
            end
        end
        TNode => error()
        SNode => error()
        CNode => error()
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
function updated(node::Node{K,V}, pos, in) where {K,V}
    @cases node begin
        CNode(array, bitmap) => begin
            narr = copy(array)
            narr[pos] = in
            return CNode{K,V}(narr, bitmap)
        end
        LNode => error()
        SNode => error()
        TNode => error()
    end
end

# Insert `sn` to `cn` at pos
# https://github.com/scala/scala/blob/0d0d2195d7ea31f44d979748465434283c939e3b/src/library/scala/collection/concurrent/TrieMap.scala#L576C1-L585C1
function cnode_inserted(node::Node{K,V}, pos, flag, sn) where {K,V}
    @cases node begin
        CNode(data, bitmap) => begin
            arr = data
            bmp = bitmap | flag
            len = length(arr)
            narr = similar(arr, len + 1)

            narr[1:(pos-1)] = arr[1:(pos-1)]
            narr[pos] = sn
            narr[(pos+1):end] = arr[(pos):end]
            return CNode{K,V}(narr, bmp)
        end
        LNode => error()
        TNode => error()
        SNode => error()
    end
end

function lnode_inserted(node::Node{K,V}, k, v) where {K,V}
    @cases node begin
        LNode => LNode{K,V}(SNode{K,V}(k, v), node)
        TNode => error()
        SNode => error()
        CNode => error()
    end
end



# https://github.com/scala/scala/blob/0d0d2195d7ea31f44d979748465434283c939e3b/src/library/scala/collection/concurrent/TrieMap.scala#L656
function dual(x::Node{K,V}, xhc::UInt, y::Node{K,V}, yhc::UInt, lev::Int, gen::Gen) where {K,V}
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
        inner = LNode{K,V}(y, nothing)
        return LNode{K,V}(x, inner)
    end
end

# Fig. 6: Insert operation
function iinsert(i::INode{K,V}, key, val, lev, parent) where {K,V}
    n = i.main
    hc = hash(key)
    @cases n begin
        CNode(data, bitmap) => begin
            cn = n
            flag, pos = flagpos(hc, lev, bitmap)
            if bitmap ⊙ flag == 0
                ncn = cnode_inserted(cn, pos, flag, SNode{K,V}(key, val))
                _, cas_suceeded = @atomicreplace i.main cn => ncn
                if cas_suceeded
                    return OK
                else
                    return RESTART
                end
            end
            x = data[pos]
            if x isa INode
                sin = x
                return iinsert(sin, key, val, lev + W, i)
            end
            @cases x begin
                LNode => error()
                TNode => error()
                CNode => error()
                SNode(sk, sv) => begin
                    sn = x
                    if !isequal(sk, key)
                        nsn = SNode{K,V}(key, val)

                        # TODO: which gen
                        gen = Gen()
                        inner_c = dual(sn, hash(sk), nsn, hc, lev + 5, gen)
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

            end
        end
        # Will error once `clean` is implemented as part of compression
        TNode => begin
            clean(parent, lev - W)
            return RESTART
        end
        LNode => begin
            ln = n
            nln = lnode_inserted(ln, key, val)
            _, cas_suceeded = @atomicreplace i.main ln => nln
            if cas_suceeded
                return OK
            else
                return RESTART
            end
        end
        SNode => error("Did not expect SNode here")
    end
end

end # module
