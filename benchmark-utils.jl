
PERFORMANCE_TEST_COMMAND = `./julia/julia ./julia/test/perf/micro/perf.jl`


function parse_micro_benchmarks(raw_results)
    micro_times = Dict()
    results = split(raw_results, '\n')

    # get the average results for each test
    for result in results
        isempty(result) && continue

        r = split(result, ',')
        test = r[2]
        time = parse(r[5])

        micro_times[test] = time
    end

    micro_times
end

function establish_baseline_times()
    try
        run(`rm passes.conf`)
    catch
        # just removing the file, doesn't matter if it wasn't there
    end

    run_benchmarks()
end

function run_benchmarks()
    gc()
    raw_results = readall(PERFORMANCE_TEST_COMMAND)
    parse_micro_benchmarks(raw_results)
end
