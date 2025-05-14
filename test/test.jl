using WeightedMovingQuantileTrees
using DataStructures
using LinearAlgebra
using Random
using Dates

tree = WeightedMovingQuantileTree( 3, Int )

push!( tree, 4 )

@assert( tree.root[] == 1 )
@assert( tree.free == 2 )
@assert( tree.value[1] == 4 )
@assert( tree.left_weight[1] == 1 )
@assert( tree.left_count[1] == 1 )

push!( tree, 1 )

@assert( tree.children[1,1] == 2 )
@assert( tree.left_weight[1] == 3 )
@assert( tree.left_count[1] == 2 )
@assert( tree.value[2] == 1 )
@assert( tree.left_weight[2] == 2 )
@assert( tree.left_count[2] == 1 )

@assert( argmax( tree )[] == 1 )

push!( tree, 2 )

@assert( tree.children[2,2] == 3 )
@assert( tree.value[3] == 2 )
@assert( tree.left_weight[3] == 3 )
@assert( tree.left_count[3] == 1 )
@assert( tree.left_weight[2] == 2 )
@assert( tree.left_count[2] == 1 )
@assert( tree.left_weight[1] == 6 )
@assert( tree.left_count[1] == 3 )

delete!( tree, 4 )

@assert( tree.root[] == 2 )
@assert( tree.value[2] == 1 )
@assert( tree.children[1,2] == 0 )
@assert( tree.children[2,2] == 3 )
@assert( tree.left_weight[2] == 2 )
@assert( tree.weight[2] == 2 )
@assert( tree.free == 1 )
@assert( unique(tree.children[:,1]) == [0] )

push!( tree, 3 )

@assert( tree.root[] == 2 )
@assert( tree.value[2] == 1 )
@assert( tree.children[:,2] == [0,3] )
@assert( tree.left_weight[2] == 2 )
@assert( tree.value[3] == 2 )
@assert( tree.children[:,3] == [0,1] )
@assert( tree.left_weight[3] == 3 )
@assert( tree.value[1] == 3 )
@assert( tree.left_weight[1] == 4 )

delete!( tree, 1 )

push!( tree, 2 )
@assert( tree.root[] == 3 )
@assert( tree.left_weight[3] == 8 )
@assert( tree.weight[3] == 8 )
@assert( tree.children[:,3] == [0,1] )

quantile( tree, 0.5 )
quantile( tree, 0.75 )
@assert( abs( quantile( tree, 0.75 ) - (0.75-2/3)/(1/3)*3 - (1-0.75)/(1/3)*2 ) < 1e-8 )

a = [1, 2, 3, 4, 3, 2, 3, 4, 4, 2, 0]
N = 4
tree = WeightedMovingQuantileTree( N, Int )
qs = []
for i = 1:length(a)-1
    if i > N
        push!( qs, quantile( tree, 0.5 ) )
        delete!( tree, a[i-N] )
    end
    push!(tree, a[i])
end

w = 1:4
total = sum(w)
qsm = []
for j = 1:length(qs)
    x = a[j:j+3]
    p = sortperm( x )
    sd = (v -> SortedDict( v .=> zeros(length(v)) ))(unique(x[p]))
    [sd[x[i]] += w[i] for i in 1:length(x)]

    ks = keys(sd)
    cs = cumsum(values(sd))
    pt = 0.5*total
    r = searchsorted(cs, pt)
    (k1, k2) = (r.stop, r.start)
    if k1 == k2
        q = x[p][k1]
    else
        q = ((pt - cs[k1])*x[p][k2] + (cs[k2] - pt)*x[p][k1])/(cs[k2] - cs[k1])
    end
    push!( qsm, q )
end
@assert( norm( qsm .- qs, Inf ) < 1e-8 )

function check_left_count( a, tree, i = tree.root[] )
    rc = 0
    if tree.children[2,i] != 0
        rc = check_left_count( a, tree, tree.children[2,i] )
    end
    lc = 0
    if tree.children[1,i] != 0
        lc = check_left_count( a, tree, tree.children[1,i] )
    end
    @assert( tree.left_count[i] == lc + sum(a .== tree.value[i]), "Left count doesn't match for node $i" )
    return tree.left_count[i] + rc
end

Random.seed!(1)
x = rand(1:10, 1_000_000 );
N = 4
tree = WeightedMovingQuantileTree( N, Int )
qs = []
printevery = 10_000
println( "Starting at $(now())" )
for i = 1:length(x)
    if i > N
        push!( qs, quantile( tree, 0.5 ) )
        delete!( tree, x[i-N] )
        check_left_count( x[i-N+1:i-1], tree )
    end
    push!(tree, x[i])
    check_left_count( x[max(1,i-N+1):i], tree )
    if i % printevery == 0
        println( "Done $i iterations at $(now())" )
    end
end

N = 6
tree = WeightedMovingQuantileTree( N, Int )
qs = []
printevery = 10_000
println( "Starting at $(now())" )
for i = 1:length(x)
    if i > N
        push!( qs, quantile( tree, 0.5 ) )
        delete!( tree, x[i-N] )
        check_left_count( x[i-N+1:i-1], tree )
    end
    push!(tree, x[i])
    check_left_count( x[max(1,i-N+1):i], tree )
    if i % printevery == 0
        println( "Done $i iterations at $(now())" )
    end
end

N = 20
x = rand(1:1_000, 1_000_000 );
tree = WeightedMovingQuantileTree( N, Int )
qs = []
printevery = 10_000
println( "Starting at $(now())" )
for i = 1:length(x)
    if i > N
        push!( qs, quantile( tree, 0.5 ) )
        delete!( tree, x[i-N] )
        check_left_count( x[i-N+1:i-1], tree )
    end
    push!(tree, x[i])
    check_left_count( x[max(1,i-N+1):i], tree )
    if i % printevery == 0
        println( "Done $i iterations at $(now())" )
    end
end
