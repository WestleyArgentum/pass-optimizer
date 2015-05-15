
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
    # run the benchmarks without any passes configured
    run_benchmarks([])
end

function run_benchmarks(passes::Array)
    pass_file = open("passes.conf", "w")
    write(pass_file, join(passes, '\n'))
    close(pass_file)

    run_benchmarks()
end

function run_benchmarks()
    gc()
    raw_results = readall(PERFORMANCE_TEST_COMMAND)
    parse_micro_benchmarks(raw_results)
end
