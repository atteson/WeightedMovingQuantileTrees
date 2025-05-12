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

@assert( argmax( tree ) == 1 )

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

import WeightedMovingQuantileTrees: update!
v = 4
