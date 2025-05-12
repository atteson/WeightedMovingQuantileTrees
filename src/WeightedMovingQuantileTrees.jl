module WeightedMovingQuantileTrees

using Statistics

import Base: push!, delete!, getindex
import Statistics: quantile

export quantile

export WeightedMovingQuantileTree

mutable struct WeightedMovingQuantileTree{I,V,W}
    children::Matrix{I}
    value::Vector{V}
    left_weight::Vector{W}
    left_count::Vector{I}
    
    root::I
    free::I
    current_weight::W
end

index_types = [UInt8, UInt16, UInt32, UInt64]
index_sizes = 256 .<< sizeof.(index_types)

function WeightedMovingQuantileTree( n::Int, V, W = Int )
    I = index_types[findfirst( index_sizes .> n )]
    tree = WeightedMovingQuantileTree( zeros( I, 2, n ), zeros( V, n ), zeros( W, n ), zeros( I, n ),
                                       zero( I ), one( I ), one( W ) )
    tree.children[1,:] = I[2:n;0]
    return tree
end

function getindex( tree::WeightedMovingQuantileTree{I, V, W}, v::V;
                   f = (tree, d, i) -> nothing, # action to take at each node visited
                   ) where {I,V,W}
    if tree.root == 0
        return (0, I(0))
    else
        parent = I(0)
        child = I(1)
        c = cmp( v, tree.value[child] )
        d = div(c+3,2)
        f( tree, d, child )
        while c != 0 && tree.children[d, child] != 0
            child = tree.children[d, child]
            parent = child
            f( tree, d, child )
            c = cmp( v, tree.value[child] )
            d = div(c+3,2)
        end
        if c == 0
            return (parent, c) # return parent if it's an exact match so delete can update parent's children
        else
            return (child, c)
        end
    end
end

function alloc!( tree::WeightedMovingQuantileTree{I,V,W} ) where {I,V,W}
    # allocation for fixed-length prE-allocated objects is constant time using a stack
    if tree.free == 0
        error( "Out of space" )
    else
        result = tree.free
        tree.free = tree.children[1, result]
        tree.children[1, result] = 0
        return result
    end
end

function free!( tree::WeightedMovingQuantileTree{I,V,W}, i ) where {I,V,W}
    tree.children[1,i] = tree.free
    tree.children[2,i] = 0
    tree.free = i
end

function update!( direction )
    return ( tree, d, i ) -> 
        if d == 1
            tree.left_weight[i] += direction*(tree.current_weight + (direction < 0) * length(tree.value))
            tree.left_count[i] += direction
        end
end

function push!( tree::WeightedMovingQuantileTree{I, V, W}, v::V ) where {I,V,W}
    (i,c) = getindex( tree, v, f = update!(1) )
    d = div( c+3, 2 )
    if i == 0 || tree.children[d,i] == 0
        j = alloc!( tree )
        if i == 0
            tree.root = j
        else
            tree.children[d,i] = j
        end
        tree.value[j] = v
        tree.left_weight[j] = tree.current_weight
        tree.left_count[j] = 1
    elseif c == 0
        increment!( tree, i )
    else
        error( "Couldn't find the right spot to insert node" )
    end
    tree.current_weight += 1
end

function delete!( tree::WeightedMovingQuantileTree{I, V, W}, v::V ) where {I,V,W}
    (i, c) = getindex( tree, v, f = update!(-1) )
    d = div( c+3, 2 )
    if c == 0
        decrement!( tree, i )
        if tree.weight[i] == 0
            z = tree.children[:,i] .== 0
            nz = sum(z)
            if nz == 0
            end
        elseif tree.weight[i] < 0
            error( "Negative weight on deletion" )
        end
            
    else
        error( "Couldn't find node to delete" )
    end
end


function quantile( tree::WeightedMovingQuantileTree{I, V, W}, p ) where {I,V,W}
end

end # module WeightedMovingQuantilTrees
