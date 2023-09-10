using ConcurrentHashTries
const CHT = ConcurrentHashTries
using Test
using PropCheck


struct ZerHash1{T}
    x::T
end
struct ZerHash2{T}
    x::T
end
Base.hash(::ZerHash1, ::UInt) = zero(UInt)
Base.hash(::ZerHash2, ::UInt) = zero(UInt)

@testset "ConcurrentHashTries.jl" begin
    @testset "basic insert + lookup" begin

        c = Ctrie{Int,Int}()
        insert(c, 1, 1)
        @test lookup(c, 1) == 1

        insert(c, 1, 2)
        @test lookup(c, 1) == 2


        insert(c, 2, 3)
        @test lookup(c, 1) == 2
        @test lookup(c, 2) == 3
    end

    @testset "hash collision insert + lookup" begin
        c = Ctrie()

        a = ZerHash1(0)
        b = ZerHash2(1)
        insert(c, a, 1)
        @test lookup(c, a) == 1
        @test lookup(c, b) == CHT.NOTFOUND
        insert(c, b, 2)

        @test lookup(c, b) == 2
        @test lookup(c, a) == 1
    end

    @testset "concurrent insert + lookup" begin
        c = Ctrie{Int,Int}()
        Threads.@sync for i = 1:10000
            # Both writing same value to same slot
            Threads.@spawn insert(c, i, 2 * i)
            Threads.@spawn insert(c, i, 2 * i)
        end

        results = fetch.([Threads.@spawn lookup(c, i) for i = 1:1000])
        @test results == 2:2:2000


        # Everyone racing for slot 1
        c = Ctrie{Int,Int}()
        Threads.@sync for i = 1:100
            Threads.@spawn begin
                rand()
                insert(c, 1, i)
            end
        end
        # Someone won
        @test lookup(c, 1) in 1:100

        c = Ctrie{ZerHash1{Int},Int}()
        # Every slot contested by two threads
        Threads.@sync for i = 1:1000
            Threads.@spawn insert(c, ZerHash1(i), i)
            Threads.@spawn insert(c, ZerHash1(i), 2 * i)
        end

        r = fetch.([Threads.@spawn lookup(c, ZerHash1(i)) for i = 1:1000])
        for i = 1:1000
            # Someone won the race
            @test r[i] == i || r[i] == 2i
        end

    end

    @testset "PropCheck lookup + insert" begin
        function insert_lookup_empty(k, v)
            c = Ctrie()
            insert(c, k, v)
            return lookup(c, k) == v
        end

        c = Ctrie()
        function insert_lookup_stateful(k, v)
            insert(c, k, v)
            return lookup(c, k) == v
        end

        for T in (Int, Float64, UInt, UInt8)
            @test check(splat(insert_lookup_empty), itype(Tuple{T,T}))
            collide(args) = map(ZerHash1, args)
            @test check(splat(insert_lookup_empty) ∘ collide, itype(Tuple{T,T}))

            @test check(splat(insert_lookup_stateful), itype(Tuple{T,T}))
            @test check(splat(insert_lookup_stateful) ∘ collide, itype(Tuple{T,T}))
        end

    end
end
