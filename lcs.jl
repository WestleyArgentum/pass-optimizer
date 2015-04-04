
function longest_common_subsequence(a, b; result_base = "", join_fn = string)
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
    result = result_base
    a_start, a_end = 0, 0
    b_start, b_end = 0, 0

    while x != 1 && y != 1
        if lengths[x, y] == lengths[x-1, y]
            x -= 1
        elseif lengths[x, y] == lengths[x, y-1]
            y -= 1
        else
            result = join_fn(a[x-1], result)

            a_start = x - 1
            b_start = y - 1

            if (a_end == 0)
                a_end = x - 1
                b_end = y - 1
            end

            x -= 1
            y -= 1
        end
    end

    result, a_start:a_end, b_start:b_end
end

longest_common_subsequence(a::Array, b::Array) = longest_common_subsequence(a, b, result_base = [], join_fn = vcat)


function longest_contiguous_subsequence(a, b)
    m = zeros(length(a) + 1, length(b) + 1)
    longest, x_longest, y_longest = 0, 0, 0

    for x in 2:(length(a) + 1)
        for y in 2:(length(b) + 1)

            if a[x - 1] == b[y - 1]
                m[x, y] = m[x - 1, y - 1] + 1

                if m[x, y] > longest
                    longest = m[x, y]
                    x_longest = x
                    y_longest = y
                end
            else
                m[x, y] = 0
            end

        end
    end

    (x_longest - longest):(x_longest - 1), (y_longest - longest):(y_longest - 1)
end
