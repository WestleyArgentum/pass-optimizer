
module PassGA

include("./lcs.jl")
include("benchmark-utils.jl")

using GeneticAlgorithms
using JSON

HISTORY_FILE = "pass-ga.json"
MAX_GENERATIONS = 1024

INITAL_POP_SIZE = 48
ELITEISM_SIZE = 8
TOURNAMENT_SIZE = 40



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
    "createAggressiveDCEPass",
    "createConstantPropagationPass",
    "createAlignmentFromAssumptionsPass",
    "createDeadInstEliminationPass",
    "createDeadCodeEliminationPass",
    "createBitTrackingDCEPass",
    "createSROAPass",
    "createInductiveRangeCheckEliminationPass",
    "createLoopInterchangePass",
    "createLoopStrengthReducePass",
    "createLoopInstSimplifyPass",
    "createSimpleLoopUnrollPass",
    "createLoopRerollPass",
    "createFlattenCFGPass",
    "createStructurizeCFGPass",
    "createTailCallEliminationPass",
    "createMergedLoadStoreMotionPass",
    "createMemCpyOptPass",
    "createConstantHoistingPass",
    "createLowerAtomicPass",
    "createCorrelatedValuePropagationPass",
    "createLowerExpectIntrinsicPass",
    "createPartiallyInlineLibCallsPass",
    "createSampleProfileLoaderPass",
    "createScalarizerPass",
    "createAddDiscriminatorsPass",
    "createSeparateConstOffsetFromGEPPass",
    "createSpeculativeExecutionPass",
    "createLoadCombinePass",
    "createStraightLineStrengthReducePass",
    "createPlaceSafepointsPass",
    "createRewriteStatepointsForGCPass",
    "createNaryReassociatePass",
    "createLoopDistributePass"
]

# -------

type PassMonster <: Entity
    passes::Array{UTF8String, 1}
    fitness
    elite

    results_micro::Dict{UTF8String, Float64}

    PassMonster(; elite = false) = new(Array(UTF8String, 0), 0.0, elite, Dict{UTF8String, Float64}())
    PassMonster(passes::Array{UTF8String, 1}; elite = false) = new(passes, 0.0, elite, Dict{UTF8String, Float64}())
end

function Base.isless(lhs::PassMonster, rhs::PassMonster)
    abs(lhs.fitness) > abs(rhs.fitness)
end

function Base.show(io::IO, monster::PassMonster)
    println(io, monster.fitness)
    println(io, monster.results_micro)
    println(io, monster.passes)
end

function pick_one(pass_set::Array)
    return pass_set[rand(1:length(pass_set))]
end

function validate_and_patch(monster::PassMonster)
    dependency_map = {
        "createLoopVectorizePass" => {
            "one_of" => [
                "createLoopIdiomPass",
                "createLoopRotatePass",
                "createLoopUnswitchPass",
                "createLoopDeletionPass",
                "createLoopUnrollPass"
            ]
        }
    }

    seen = Set()
    i = 1
    while i <= length(monster.passes)
        pass = monster.passes[i]
        push!(seen, pass)

        deps = get(dependency_map, pass, nothing)
        if deps != nothing && haskey(deps, "one_of")
            # if any of the passes specified in one_of are found, the
            # dependency has been met -- otherwise we need to patch
            if length(intersect(seen, deps["one_of"])) < 1
                insert!(monster.passes, rand(1:i), pick_one(deps["one_of"]))
                i += 1
            end
        end
        # add other cases like `all_of` here

        i += 1
    end

    monster
end

# -------

function create_entity(num)
    monster = PassMonster()

    num_passes = rand(5:50)
    for i in 1:num_passes
        push!(monster.passes, pick_one(passes))
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
        gc()

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
        # limit the punishment for taking longer than unoptomized
        monster.fitness += min(time / BASELINE_TIMES[test], 1.25)
    end

    println("$(monster.fitness)  $(monster.results_micro)")

    monster.fitness
end

function group_entities(pop)
    # save the generation!
    history_file = open(HISTORY_FILE, "a")
    write(history_file, json(pop))
    write(history_file, ",\n")
    close(history_file)

    println("BEST OF GENERATION: ", pop[1])

    if generation_num() > MAX_GENERATIONS
        return
    end

    elite_selection(pop, ELITEISM_SIZE)
    tournament_selection(pop, TOURNAMENT_SIZE; compare_fn = <)
end

function crossover(parents)
    length(parents) == 1 && return PassMonster(parents[1].passes; elite = true)

    synapsing_variable_length_crossover(parents)
end

function mutate(monster)
    (rand() < 0.5 || monster.elite) && return

    # decrease the effects of mutation over time
    rate = (MAX_GENERATIONS - generation_num()) / MAX_GENERATIONS

    num_to_mutate = rand(1:int(5 * rate))
    add_remove_modify = rand(1:3)
    where = length(monster.passes) > 0 ? rand(1:length(monster.passes)) : 1

    if add_remove_modify == 1
        # add passes
        for i in 1:num_to_mutate
            insert!(monster.passes, where, pick_one(passes))
        end

    elseif add_remove_modify == 2
        # remove passes
        last = min(where + num_to_mutate, length(monster.passes))
        splice!(monster.passes, where:last)

    else
        # modify passes
        new_passes = [ pick_one(passes) for i in 1:num_to_mutate ]
        last = min(where + num_to_mutate, length(monster.passes))
        splice!(monster.passes, where:last, new_passes)
    end

    monster
end

# -------

function elite_selection(pop, num)
    [ produce([i]) for i in 1:num ]
end

function tournament_selection(pop, num; selection_probability = 0.75, compare_fn = >)
    function run_tournament(pop, selection_probability)
        contestant1 = rand(1:length(pop))
        contestant2 = rand(1:length(pop))

        # pick unique contestants
        while contestant1 == contestant2
            contestant2 = rand(1:length(pop))
        end

        if rand() < selection_probability
            # return the fittest of the contestants
            return compare_fn(pop[contestant1].fitness, pop[contestant2].fitness) ? contestant1 : contestant2
        else
            # return the least fit of the contestants
            return compare_fn(pop[contestant1].fitness, pop[contestant2].fitness) ? contestant2 : contestant1
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

    # If the LCS is small compared to the length of the parent genomes
    # it probably isn't contributing much to the fitness score.
    # Instead of preserving it, we should preserve other sequences
    # from the parents.
    min_genome_length = min(length(genome1), length(genome2))
    seq_length = length(shared_seq)
    if shared_seq == nothing || seq_length == 0 || min_genome_length == 0 || seq_length / min_genome_length < 0.3
        return cut_and_splice(genome1, genome2)
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

function cut_and_splice(genome1, genome2)
    length(genome1) < 1 && return genome2
    length(genome2) < 1 && return genome1

    cut1 = rand(1:length(genome1))
    cut2 = rand(1:length(genome2))

    if rand() < 0.5
        return [ genome1[1:cut1], genome2[cut2:end] ]
    else
        return [ genome2[1:cut2], genome1[cut1:end] ]
    end
end

function synapsing_variable_length_crossover(parents)
    length(parents) != 2 && error("synapsing_variable_length_crossover works on exactly 2 parents")

    PassMonster(svlc(parents[1].passes, parents[2].passes))
end

# -------

println("Establishing baseline performance test times...")
BASELINE_TIMES = establish_baseline_times()
println("BASELINE TIMES: ", BASELINE_TIMES)

end

# -------

using GeneticAlgorithms

println("Running GA!")

model = runga(PassGA; initial_pop_size = PassGA.INITAL_POP_SIZE)

println(population(model))
