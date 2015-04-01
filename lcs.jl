
function lcs(a, b)
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

    result = ""
    x, y = length(a) + 1, length(b) + 1

    while x != 1 && y != 1
        if lengths[x, y] == lengths[x-1, y]
            x -= 1
        elseif lengths[x, y] == lengths[x, y-1]
            y -= 1
        else
            a[x-1] != b[y-1] && error()
            result = string(a[x-1], result)
            x -= 1
            y -= 1
        end
    end

    result
end
