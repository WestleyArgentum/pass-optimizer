
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

function compare_layouts(passes)
    println("establishing baseline times...")
    baseline_times = establish_baseline_times()

    println("establishing standard julia pass layout times...")
    standard_passes = split(readall("./example/standard-passes.conf"), '\n')
    standard_times = run_benchmarks(standard_passes)

    println("establishing custom pass layout times...")
    custom_times = run_benchmarks(passes)

    results = {
        "standard" => {
            "passes" => standard_passes,
            "results_micro" => standard_times,
            "results_relative" => Dict()
        },
        "custom" => {
            "passes" => passes,
            "results_micro" => custom_times,
            "results_relative" => Dict()
        }
    }

    # compute the scores for each test, relative to the baseline
    for (test, time) in baseline_times
        results["standard"]["results_relative"][test] = standard_times[test] / time
        results["custom"]["results_relative"][test] = custom_times[test] / time
    end

    # compute the fitness for each pass layout
    results["standard"]["fitness"] = 0.0
    results["custom"]["fitness"] = 0.0
    for layout in ["standard", "custom"]
        for (test, score) in results[layout]["results_relative"]
            results[layout]["fitness"] += score
        end
    end

    results
end

function evaluate_best_of_run(output::Dict)
    compare_layouts(output["best_entity"]["passes"])
end

function evaluate_best_of_run(filename::String)
    output = analyze_run(filename)
    evaluate_best_of_run(output)
end
