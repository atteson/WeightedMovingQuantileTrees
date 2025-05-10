module WeightedMovingQuantileTrees

struct WeightedMovingQuantileTree{I,V,W}
    children::Matrix{I}
    values::Vector{V}
    left_weights::Vector{W}
    left_count::Vector{I}
    current_weight::W
    free::I
end

index_types = [UInt8, UInt16, UInt32, UInt64]
index_sizes = 256 << sizeof.(index_types)

function WeightedMovingQuantileTree( n::Int, V, W = Int )
    I = index_types[findfirst( index_sizes .> n )]
    tree = WeightedMovingQuantileTree( zeros( I, 2, n ), zeros( V, n ), zeros( W, n ), zeros( I, n ), one( W ), U(1) )
    tree.children[1,:] = U[2:n;0]
    return tree
end

function find( tree::WeightedMovingQuantileTree{I, V, W}, v::V ) where {I,V,W}
    if tree.weights[1] == 0
        return (0, 0)
    else
        i = 1
        c = cmp( tree.values[i], v )
        d = div(c+3,2)
        while c != 0 && tree.children[d, i] != 0
            i = tree.children[d, parent]
            c = cmp( tree.values[i], v )
            d = div(c+3,2)
        end
        return (d, i)
    end
end

function alloc( tree::WeightedMovingQuantileTree{I,V,W} ) where {I,V,W}
    # allocation for fixed-length pre-heap-allocated objects is constant time using a stack
    if tree.free == 0
        error( "Out of space" )
    else
        result = tree.free
        tree.children[1, result] = 0
        tree.free = tree.children[1, tree.free]
        return result
    end
end

function free( tree::WeightMovingQuantileTree{I,V,W}, i ) where {I,V,W}
    tree.children[1,i] = tree.free
    tree.children[2,i] = 0
    tree.free = i
end

function insert( tree::WeightedMovingQuantileTree{I, V, W}, v::V ) where {I,V,W}
    (d, i) = find( tree, v )
    if i == 0 || tree.children[d,i] == 0
        j = alloc( tree )
        if i == 0
            tree.root = j
        else
            tree.children[d,i] = j
        end
        tree.values[j] = v
        tree.left_weights[j] = tree.current_weight
        tree.left_count[j] = 1
    elseif tree.values[tree.children[d,i]] == v
        tree.left_weights[i] += tree.current_weight
        tree.left_count[i] += 1
    else
        error( "This shouldn't happen" )
    end
    tree.current_weight += 1
end

end # module Rome
