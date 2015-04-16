
using JSON
using Gadfly

function parse_run_file(filename)
    data = JSON.parse("[" * readall(filename) * "[]]")
    deleteat!(data, length(data))
end

function analyze_run(filename)
    output = Dict()

    generations = parse_run_file(filename)

    output["num_generations"] = length(generations)

    output["best_fitness_per_generation"] = Float64[]
    output["worst_fitness_per_generation"] = Float64[]
    output["average_fitness_per_generation"] = Float64[]
    output["std_fitness_per_generation"] = Float64[]

    output["best_worst_average_std_per_generation"] = Any[]
    for g in generations
        scores = Float64[ m["fitness"] == nothing ? inf(Float64) : m["fitness"] for m in g ]
        filter!(s -> isfinite(s), scores)

        push!(output["best_fitness_per_generation"], minimum(scores))
        push!(output["worst_fitness_per_generation"], maximum(scores))
        push!(output["average_fitness_per_generation"], mean(scores))
        push!(output["std_fitness_per_generation"], std(scores))
    end

    output
end

function visualize_output(output; filename = "run-output.svg")
    len = output["num_generations"]

    average = plot(x=collect(1:len), y=output["average_fitness_per_generation"])
    best = plot(x=collect(1:len), y=output["best_fitness_per_generation"])
    worst = plot(x=collect(1:len), y=output["worst_fitness_per_generation"])
    std = plot(x=collect(1:len), y=output["std_fitness_per_generation"])

    stacked = vstack(average, best, worst, std)
    draw(SVG(filename, 10inch, 20inch), stacked)
end
