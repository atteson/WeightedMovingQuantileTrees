using WeightedMovingQuantileTrees

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
@assert( quantile( tree, 0.75 ) == (0.75-2/3)/(1/3)*3 + (1-0.75)/(1/3)*2 )

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

v = a[11-4]
import WeightedMovingQuantileTrees: update!
