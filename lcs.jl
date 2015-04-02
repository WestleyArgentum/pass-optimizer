
function lcs(a, b; join_fn = string)
    lengths = zeros(length(a) + 1, length(b) + 1)

    for (i, x) in enumerate(a)
        for (j, y) in enumerate(b)
            if x == y
                lengths[i+1, j+1] = lengths[i, j] + 1
            else
                lengths[i+1, j+1] = max(lengths[i+1, j], lengths[i, j+1])
            end
        end
    end

    x, y = length(a) + 1, length(b) + 1
    result = nothing

    while x != 1 && y != 1
        if lengths[x, y] == lengths[x-1, y]
            x -= 1
        elseif lengths[x, y] == lengths[x, y-1]
            y -= 1
        else
            result = result != nothing ? join_fn(a[x-1], result) : a[x-1]
            x -= 1
            y -= 1
        end
    end

    result
end
