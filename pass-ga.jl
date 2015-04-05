
module PassGA

include("./lcs.jl")

using GeneticAlgorithms
using JSON

HISTORY_FILE = "pass-ga.json"
MAX_GENERATIONS = 1024

PERFORMANCE_TEST_COMMAND = `./julia/julia ./julia/test/perf/micro/perf.jl`

passes = [
    "createAddressSanitizerFunctionPass",
    "createTypeBasedAliasAnalysisPass",
    "createBasicAliasAnalysisPass",
    "createCFGSimplificationPass",
    "createPromoteMemoryToRegisterPass",
    "createInstructionCombiningPass",
    "createScalarReplAggregatesPass",
    "createJumpThreadingPass",
    "createReassociatePass",
    "createEarlyCSEPass",
    "createLoopIdiomPass",
    "createLoopRotatePass",
    "createLowerSimdLoopPass",
    "createLICMPass",
    "createLoopUnswitchPass",
    "createIndVarSimplifyPass",
    "createLoopDeletionPass",
    "createLoopUnrollPass",
    "createLoopVectorizePass",
    "createGVNPass",
    "createSCCPPass",
    "createSinkingPass",
    "createInstructionSimplifierPass",
    "createJumpThreadingPass",
    "createDeadStoreEliminationPass",
    "createSLPVectorizerPass",
    "createAggressiveDCEPass"
]

# -------

type PassMonster <: Entity
    passes::Array{UTF8String, 1}
    fitness

    results_micro::Dict{UTF8String, Float64}

    PassMonster() = new(Array(UTF8String, 0), 0.0, Dict{UTF8String, Float64}())
    PassMonster(passes::Array{UTF8String, 1}) = new(passes, 0.0, Dict{UTF8String, Float64}())
end

function Base.isless(lhs::PassMonster, rhs::PassMonster)
    abs(lhs.fitness) > abs(rhs.fitness)
end

# -------

function create_entity(num)
    monster = PassMonster()

    num_passes = rand(1:50)
    for i in 1:num_passes
        push!(monster.passes, passes[rand(1:length(passes))])
    end

    monster
end

function fitness(monster)
    # set up this monsters set of passes
    pass_file = open("passes.conf", "w")
    write(pass_file, join(monster.passes, '\n'))
    close(pass_file)

    # run the micro benchmarks
    raw_results = ""

    try
        raw_results = readall(PERFORMANCE_TEST_COMMAND)
    catch err
        println("\nPass set caused a crash in julia: ")
        println(err)

        println()

        println("Failing pass set: ")
        println(join(monster.passes, '\n'))

        println("\n-------\n")

        return inf(Float64)
    end

    monster.results_micro = parse_micro_benchmarks(raw_results)

    monster.fitness = 0.0
    for (test, time) in monster.results_micro
        # normalize all times between 0 - 1 so that they have equal weight
        monster.fitness += min(time / BASELINE_TIMES[test], 1.0)
    end

    println("$(monster.fitness)  $(monster.results_micro)")

    monster.fitness
end

function group_entities(pop)
    # save the generation!
    history_file = open(HISTORY_FILE, "a")
    write(history_file, json(pop))
    close(history_file)

    println("BEST OF GENERATION: ", pop[1])

    if generation_num() > MAX_GENERATIONS
        return
    end

    elite_selection(pop, 6)
    tournament_selection(pop, 26)
end

function crossover(parents)
    length(parents) == 1 && return parents[1]

    synapsing_variable_length_crossover(parents)
end

function mutate(monster)
    # decrease the effects of mutation over time
    rate = (MAX_GENERATIONS - generation_num()) / MAX_GENERATIONS

    num_to_mutate = rand(0:int(5 * rate))
    add_remove_modify = rand(1:3)
    where = length(monster.passes) > 0 ? rand(1:length(monster.passes)) : 1

    if add_remove_modify == 1
        # add passes
        for i in 1:num_to_mutate
            insert!(monster.passes, where, passes[rand(1:length(passes))])
        end

    elseif add_remove_modify == 2
        # remove passes
        last = min(where + num_to_mutate, length(monster.passes))
        splice!(monster.passes, where:last)

    else
        # modify passes
        new_passes = [ passes[rand(1:length(passes))] for i in 1:num_to_mutate ]
        last = min(where + num_to_mutate, length(monster.passes))
        splice!(monster.passes, where:last, new_passes)
    end
end

# -------

function elite_selection(pop, num)
    [ produce([i]) for i in 1:num ]
end

function tournament_selection(pop, num, selection_probability = 0.75)
    function run_tournament(pop, selection_probability)
        contestant1 = rand(1:length(pop))
        contestant2 = rand(1:length(pop))

        # pick unique contestants
        while contestant1 == contestant2
            contestant2 = rand(1:length(pop))
        end

        if rand() < selection_probability
            # return the fittest of the contestants
            return pop[contestant1].fitness > pop[contestant2].fitness ? contestant1 : contestant2
        else
            # return the least fit of the contestants
            return pop[contestant1].fitness > pop[contestant2].fitness ? contestant2 : contestant1
        end
    end

    for i in 1:num
        produce([
            run_tournament(pop, selection_probability),
            run_tournament(pop, selection_probability)
        ])
    end
end

function svlc(genome1, genome2)
    shared_seq, range1, range2 = longest_common_subsequence(genome1, genome2)
    if shared_seq == nothing || length(shared_seq) < 2
        return rand() < 0.5 ? genome1 : genome2
    end

    seq1, seq2 = genome1[range1], genome2[range2]

    child_seq = [ first(shared_seq) ]

    s1, s2 = 2, 2
    extra1, extra2 = String[], String[]

    for curr_s in shared_seq[2:end]
        while seq1[s1] != curr_s
            push!(extra1, seq1[s1])
            s1 += 1
        end

        while seq2[s2] != curr_s
            push!(extra2, seq2[s2])
            s2 += 1
        end

        s1 += 1
        s2 += 1

        child_seq = [ child_seq, rand() < 0.5 ? extra1 : extra2, curr_s ]

        extra1, extra2 = String[], String[]
    end

    leading = rand() < 0.5 ? genome1[1:(first(range1) - 1)] : genome2[1:(first(range2) - 1)]
    tailing = rand() < 0.5 ? genome1[(last(range1) + 1):end] : genome2[(last(range2) + 1):end]

    [ leading, child_seq, tailing ]
end

function synapsing_variable_length_crossover(parents)
    length(parents) != 2 && error("synapsing_variable_length_crossover works on exactly 2 parents")

    PassMonster(svlc(parents[1].passes, parents[2].passes))
end

# -------

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

    # run the performance tests without any passes,
    # hopefully a worst case scenario
    raw_results = readall(PERFORMANCE_TEST_COMMAND)

    parse_micro_benchmarks(raw_results)
end

println("Establishing baseline performance test times...")
BASELINE_TIMES = PassGA.establish_baseline_times()

end

# -------

using GeneticAlgorithms

println("Running GA!")

model = runga(PassGA; initial_pop_size = 32)

println(population(model))
