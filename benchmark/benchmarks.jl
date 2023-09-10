using BenchmarkTools, ConcurrentHashTries

const SUITE = BenchmarkGroup()

SUITE["insert"] = BenchmarkGroup()

struct Collide{T}
    x::T
end
Base.hash(::Collide, h::UInt) = zero(h)

function one_hundred_inserts(T, f)
    c = Ctrie{T,Int}()
    for i = 1:100
        insert(c, f(i), i)
    end
    return c
end

SUITE["insert"]["integers"] = @benchmarkable one_hundred_inserts($Int, $identity)
SUITE["insert"]["integers_hash_colliding"] = @benchmarkable one_hundred_inserts($(Collide{Int}), $Collide)
SUITE["insert"]["integers_same_slot"] = @benchmarkable one_hundred_inserts($Int, $(Returns(1)))
