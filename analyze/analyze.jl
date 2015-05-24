
using JSON
using Gadfly

include("../benchmark-utils.jl")


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
    output["crashes_per_generation"] = Int[]

    for g in generations
        scores = Float64[ m["fitness"] == nothing ? inf(Float64) : m["fitness"] for m in g ]
        total_pop = length(scores)

        filter!(s -> isfinite(s), scores)

        push!(output["crashes_per_generation"], total_pop - length(scores))
        push!(output["best_fitness_per_generation"], minimum(scores))
        push!(output["worst_fitness_per_generation"], maximum(scores))
        push!(output["average_fitness_per_generation"], mean(scores))
        push!(output["std_fitness_per_generation"], std(scores))

        if !haskey(output, "best_entity") || output["best_entity"]["fitness"] < g[1]["fitness"]
            output["best_entity"] = g[1]
        end
    end

    output
end

function visualize(output::Dict; filename = "run-output.svg", browser = "Google Chrome")
    len = output["num_generations"]

    average = plot(x=collect(1:len), y=output["average_fitness_per_generation"],
                   Guide.XLabel("Generation"), Guide.YLabel("Average Fitness"))
    best = plot(x=collect(1:len), y=output["best_fitness_per_generation"],
                   Guide.XLabel("Generation"), Guide.YLabel("Best Fitness"))
    worst = plot(x=collect(1:len), y=output["worst_fitness_per_generation"],
                   Guide.XLabel("Generation"), Guide.YLabel("Worst Fitness"))
    std = plot(x=collect(1:len), y=output["std_fitness_per_generation"],
                   Guide.XLabel("Generation"), Guide.YLabel("Standard Deviation"))
    crashes = plot(x=collect(1:len), y=output["crashes_per_generation"],
                   Guide.XLabel("Generation"), Guide.YLabel("Crashes"))

    stacked = vstack(average, best, worst, std, crashes)
    draw(SVG(filename, 10inch, 25inch), stacked)

    run(`open -a "$browser" file://$(abspath(filename))`)
end

function visualize(filename::String; kwargs...)
    out_filename = replace(filename, ".json", "") * ".svg"
    output = analyze_run(filename)
    visualize(output; filename = out_filename, kwargs...)
end

function compare_layouts(layouts::Array)
    println("establish_baseline_times...")
    baseline_times = establish_baseline_times()

    results = Any[]

    for layout in layouts
        println("running benchmarks...")
        layout_times = run_benchmarks(layout)

        result = {
            "passes" => layout,
            "fitness" => 0.0,
            "results_relative" => Dict{String, Float64}(),
            "results_micro" => layout_times
        }

        for (test, time) in baseline_times
            relative_time = layout_times[test] / time
            result["results_relative"][test] = relative_time
            result["fitness"] += relative_time
        end

        push!(results, result)
        println("fitness: ", result["fitness"])
    end

    results
end

function standard_layout()
    split(readall("./example/standard-passes.conf"))
end
