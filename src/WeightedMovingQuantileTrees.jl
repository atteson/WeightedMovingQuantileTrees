module WeightedMovingQuantileTrees

using Statistics

import Base: push!, delete!, getindex, argmax
import Statistics: quantile

export quantile

export WeightedMovingQuantileTree

mutable struct WeightedMovingQuantileTree{I,V,W}
    children::Matrix{I}
    value::Vector{V}
    
    weight::Vector{W}
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
    tree = WeightedMovingQuantileTree( zeros( I, 2, n ), zeros( V, n ),
                                       zeros( W, n ), zeros( W, n ), zeros( I, n ),
                                       Ref(zero( I )), one( I ), one( W ) )
    tree.children[1,:] = I[2:n;0]
    return tree
end

function getindex( tree::WeightedMovingQuantileTree{I, V, W}, v::V;
                   action = (tree, d, i) -> nothing, # action to take at each node visited
                   ) where {I,V,W}
    if tree.root[] == 0
        return (tree.root, 1)
    else
        i = tree.root
        
        c = cmp( v, tree.value[i[]] )
        d = (c+3) >> 1
        
        action( tree, c, i[] )
        
        while c != 0 && i[] != 0
            i = Ref( tree.children, LinearIndices( tree.children )[d, i[]] )

            if i[] != 0
                c = cmp( v, tree.value[i[]] )
                d = (c+3) >> 1
            
                action( tree, c, i[] )
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
    tree.weight[i] = 0
    tree.free = i
end

function update!( direction )
    return ( tree, c, i ) -> 
        if c <= 0
            tree.left_weight[i] += direction*(tree.current_weight - (direction < 0) * length(tree.value))
            tree.left_count[i] += direction
        end
end

function push!( tree::WeightedMovingQuantileTree{I, V, W}, v::V ) where {I,V,W}
    (i, c) = getindex( tree, v, action = update!(1) )
    if c != 0
        j = alloc!( tree )
        i[] = j
        
        tree.value[j] = v
    
        tree.left_weight[j] = tree.current_weight
        tree.left_count[j] = 1
    end
    tree.weight[i[]] += tree.current_weight
    tree.current_weight += 1
end

function argmax( tree::WeightedMovingQuantileTree{I, V, W}, i = tree.root ) where {I,V,W}
    while tree.children[2,i[]] != 0
        i = Ref( tree.children, LinearIndices(tree.children)[2,i[]] )
    end
    return i
end

function delete!( tree::WeightedMovingQuantileTree{I, V, W}, v::V ) where {I,V,W}
    (i, c) = getindex( tree, v, action = update!(-1) )
    if c == 0
        j = i[]

        tree.weight[j] -= tree.current_weight - length(tree.value)
        if tree.weight[j] == 0
            # this means there is no more weight associated with the value tree.value[j]
            nz = tree.children[:,j] .!= 0
            nnz = sum(nz)
            if nnz <= 1
                i[] = nnz == 0 ? 0 : tree.children[nz,j][1]
                free!( tree, j )
            else
                # node has 2 children
                # need to find the next highest value to swap
                k = argmax( tree, Ref( tree.children, LinearIndices(tree.children)[1,j] ) )

                l = k[]

                tree.value[j] = tree.value[l]
                tree.weight[j] = tree.weight[l]

                w = tree.left_weight[l]
                if tree.children[1,l] != 0
                    k[] = tree.children[1,l]
                    w -= tree.left_weight[tree.children[1,l]]
                else
                    k[] = 0
                end
                tree.left_weight[j] += w
                
                free!( tree, l )
            end 
        elseif tree.weight[j] < 0
            error( "Negative weight on deletion" )
        end
    else
        error( "Couldn't find node to delete" )
    end
end

function nearestbound( tree::WeightedMovingQuantileTree{I, V, W}, target, total, direction ) where {I,V,W}
    z = tree.current_weight - length(tree.value) - 1

    bound = W(direction > 0 ? total : 0)
    value = direction > 0 ? typemax(V) : typemin(V)
    term = W(0)
    i = tree.root
    
    while i[] != 0
        w = term + tree.left_weight[i[]] - tree.left_count[i[]] * z
        c = cmp( w, target )
        if direction*c >= 0 && direction*w <= direction*bound
            bound = w
            value = tree.value[i[]]
        end
        d = (3 - c) >> 1
        term += (d == 2)*(w - term)
        i = Ref(tree.children, LinearIndices(tree.children)[d, i[]])
    end
    return (bound, value)
end

function quantile( tree::WeightedMovingQuantileTree{I, V, W}, p ) where {I,V,W}
    total = binomial( length(tree.value)+1, 2 )

    target = p * total

    (lub, lubvalue) = nearestbound( tree, target, total, 1 )
    (glb, glbvalue) = nearestbound( tree, target, total, -1 )

    if lubvalue == typemax(V)
        return glbvalue
    elseif glbvalue == typemin(V)
        return lubvalue
    else
        alpha = (target - glb)/(lub - glb)
        return alpha * lubvalue + (1-alpha) * glbvalue
    end
end

end # module WeightedMovingQuantilTrees
