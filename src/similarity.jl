using LinearAlgebra

cosine_similarity(a, b) = dot(a, b) / (norm(a) * norm(b))

struct Cluster
    items::Vector
end

function cluster(items, threshold::Float64)
    groups = Cluster[]
    for item in items
        placed = false
        for group in groups
            if cosine_similarity(item.embedding, group.items[1].embedding) >= threshold
                push!(group.items, item)
                placed = true
                break
            end
        end
        if !placed
            push!(groups, Cluster([item]))
        end
    end
    groups
end
