using WeightedMovingQuantileTrees

tree = WeightedMovingQuantileTree( 3, Int )

push!( tree, 4 )

@assert( tree.root == 1 )
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

(c,i) = tree[4]
(c,i) = tree[1]
