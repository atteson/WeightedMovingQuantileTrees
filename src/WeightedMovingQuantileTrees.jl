module WeightedMovingQuantileTrees

using Statistics

import Base: push!, delete!, getindex, argmax
import Statistics: quantile

export quantile

export WeightedMovingQuantileTree

mutable struct WeightedMovingQuantileTree{I,V,W}
    children::Matrix{I}
    value::Vector{V}
    left_weight::Vector{W}
    left_count::Vector{I}
    
    root::Ref{I}
    free::I
    current_weight::W
end

index_types = [UInt8, UInt16, UInt32, UInt64]
index_sizes = 256 .<< sizeof.(index_types)

function WeightedMovingQuantileTree( n::Int, V, W = Int )
    I = index_types[findfirst( index_sizes .> n )]
    tree = WeightedMovingQuantileTree( zeros( I, 2, n ), zeros( V, n ), zeros( W, n ), zeros( I, n ),
                                       Ref(zero( I )), one( I ), one( W ) )
    tree.children[1,:] = I[2:n;0]
    return tree
end

function getindex( tree::WeightedMovingQuantileTree{I, V, W}, v::V;
                   action = (tree, d, i) -> nothing, # action to take at each node visited
                   ) where {I,V,W}
    if tree.root[] == 0
        return (tree.root, 0)
    else
        i = tree.root
        
        c = cmp( v, tree.value[i[]] )
        d = (c+3) >> 1
        
        action( tree, d, i[] )
        
        while c != 0 && i[] != 0
            i = Ref( tree.children, LinearIndices( tree.children )[d, i[]] )

            if i[] != 0
                c = cmp( v, tree.value[i[]] )
                d = (c+3) >> 1
            
                action( tree, d, i[] )
            end
        end
        return (i, c)
        # always return reference to node pointing to where we want to insert/delete
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
            tree.left_weight[i] += direction*(tree.current_weight - (direction < 0) * length(tree.value))
            tree.left_count[i] += direction
        end
end

function push!( tree::WeightedMovingQuantileTree{I, V, W}, v::V ) where {I,V,W}
    (i, c) = getindex( tree, v, action = update!(1) )
    j = alloc!( tree )
    i[] = j
        
    tree.value[j] = v
    tree.left_weight[j] = tree.current_weight
    tree.left_count[j] = 1
    tree.current_weight += 1
end

function argmax( tree::WeightedMovingQuantileTree{I, V, W}, parent::I = tree.root[] ) where {I,V,W}
    child = parent
    while tree.children[2,child] != 0
        parent = child
        child = tree.children[2,child]
    end
    return parent
end

function delete!( tree::WeightedMovingQuantileTree{I, V, W}, v::V ) where {I,V,W}
    (i, c) = getindex( tree, v, action = update!(-1) )
    if c == 0
        j = i[]
        
        nz = tree.children[:,j] .!= 0
        if tree.left_weight[j] == sum(tree.left_weight[tree.children[Int(nz[1]),j]])
            # this means there is no more weight associated with the value tree.value[j]
            nnz = sum(nz)
            if nnz == 0
                i[] = 0
            elseif nz == 1
                i[] = tree.children[z,j]
                free( tree, j )
            else
                # node has 2 children
                # need to find the next highest value to swap
                k = argmax( tree, tree.children[2,j] )

                l = tree.children[1,k]
                tree.children[2,k] = l

                tree.value[j] = tree.value[l]

                w = tree.left_weight[l]
                if tree.children[1,l] != 0
                    w -= tree.left_weight[tree.children[1,l]]
                end
                tree.left_weight[j] += w
            end 
        elseif tree.weight[j] < 0
            error( "Negative weight on deletion" )
        end
    else
        error( "Couldn't find node to delete" )
    end
end

function quantile( tree::WeightedMovingQuantileTree{I, V, W}, p ) where {I,V,W}
end

end # module WeightedMovingQuantilTrees
