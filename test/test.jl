using WeightedMovingQuantileTrees
using DataStructures
using LinearAlgebra

tree = WeightedMovingQuantileTree( 3, Int )

push!( tree, 4 )

@assert( tree.root[] == 1 )
@assert( tree.free == 2 )
n@assert( tree.value[1] == 4 )
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

N = 4
tree = WeightedMovingQuantileTree( N, Int )
a = [1, 2, 3, 4, 3, 2, 3, 4, 4, 2, 0]
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

