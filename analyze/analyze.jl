
using JSON
using Gadfly
using DataFrames

include("../benchmark-utils.jl")


function parse_run_file(filename)
    data = JSON.parse("[" * readall(filename) * "[]]")
    deleteat!(data, length(data))
end

function run_stats(filename)
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

function visualize_run_stats(output::Dict; filename = "run-output.svg", browser = "Google Chrome")
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

function visualize_run_stats(filename::String; kwargs...)
    out_filename = replace(filename, ".json", "") * ".svg"
    output = run_stats(filename)
    visualize_run_stats(output; filename = out_filename, kwargs...)
end

function layout_benchmarks(layouts::Array)
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

function visualize_layout_benchmarks(layouts_data::Array; filename = "run-times.svg", layout_names = nothing)
    layouts = String[]
    tests = String[]
    times = Float64[]

    for i in 1:length(layouts_data)
        layout = layouts_data[i]

        for (test, time) in layout["results_relative"]
            push!(layouts, layout_names == nothing ? "layout $i" : layout_names[i])
            push!(tests, test)
            push!(times, time)
        end
    end

    table = DataFrame(layouts = layouts, tests = tests, times = times)

    relative_times_plot = plot(table, x = "layouts", y = "times", color = "tests",
                               Geom.bar(position=:dodge), Guide.YLabel("Times Relative To Unoptomized"))

    layouts = String[]
    tests = String[]
    times = Float64[]

    for i in 1:length(layouts_data)
        layout = layouts_data[i]

        for (test, time) in layout["results_micro"]
            push!(layouts, layout_names == nothing ? "layout $i" : layout_names[i])
            push!(tests, test)
            push!(times, time)
        end
    end

    table = DataFrame(layouts = layouts, tests = tests, times = times)

    absolute_times_plot = plot(table, x = "layouts", y = "times", color = "tests",
                               Geom.bar(position=:dodge), Guide.YLabel("Actual Times"))

    stacked = vstack(relative_times_plot, absolute_times_plot)
    draw(SVG(filename, 10inch, 10inch), stacked)
end

function best_of_run_benchmarks(filenames)
    run_datas = [ run_stats(run_file) for run_file in filenames ]

    layouts = [ standard_layout(), [ data["passes"] for data in run_datas ]... ]

    layout_benchmarks(layouts)
end

function visualize_best_of_run_benchmarks(filenames)
    layouts_data = best_of_run_benchmarks(filenames)
    names = [ "standard", [ first(splitext(run_file)) for run_file in filenames ]... ]

    visualize_layout_benchmarks(layouts_data; layout_names = names)
end

function standard_layout()
    split(readall("./example/standard-passes.conf"))
end
