
using JSON

function parse_run_file(filename)
    data = JSON.parse("[" * readall(filename) * "[]]")
    deleteat!(data, length(data))
end

function analyze_run(filename)
    output = Dict()

    generations = parse_run_file(filename)

    output["num_generations"] = length(generations)

    output["best_fitness_per_generation"] = [ g[1]["fitness"] for g in generations ]

    output["best_worst_average_std_per_generation"] = Any[]
    for g in generations
        scores = Float64[ m["fitness"] == nothing ? inf(Float64) : m["fitness"] for m in g ]

        stats = [ minimum(scores), maximum(scores), mean(scores), std(scores) ]
        push!(output["best_worst_average_std_per_generation"], stats)
    end

    output
end
