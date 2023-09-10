# ConcurrentHashTries

[![Build Status](https://github.com/ericphanson/ConcurrentHashTries.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/ericphanson/ConcurrentHashTries.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/ericphanson/ConcurrentHashTries.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/ericphanson/ConcurrentHashTries.jl)

Inspired by [HashArrayMappedTries.jl](https://github.com/vchuravy/HashArrayMappedTries.jl), attempts to implement [Ctries](https://en.wikipedia.org/wiki/Ctrie).

Borrows from the [scala implementation](https://github.com/scala/scala/blob/2.13.x/src/library/scala/collection/concurrent/TrieMap.scala), which is Apache 2.0 licensed, and the paper _Concurrent Tries with Efficient Non-Blocking Snapshots_ by Prokopec et al ([PDF](http://lampwww.epfl.ch/~prokopec/ctries-snapshot.pdf)).

## Status

So far only `lookup` and `insert` are implemented, and have some tests. If I continue working my way through the paper, next are `remove`, and compression operations, followed by snapshotting, then iteration, length, and so forth.
