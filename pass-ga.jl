
module PassGA

include("./lcs.jl")

using GeneticAlgorithms

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

type PassMonster <: Entity
    passes::Array{String, 1}
    fitness

    results_micro::Dict{String, Float64}

    PassMonster() = new(Array(String, 0), 0.0, Dict{String, Float64}())
    PassMonster(passes::Array{String, 1}) = new(passes, 0., Dict{String, Float64}())
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
        raw_results = readall(`./julia/julia ./julia/test/perf/micro/perf.jl`)
    catch err
        println("\nPass set caused a crash in julia: ")
        println(err)

        println()

        println("Failing pass set: ")
        println(join(monster.passes, '\n'))

        println("\n-------\n")

        return inf(Float64)
    end

    # get the average results for each test
    results = split(raw_results, '\n')
    for result in results
        isempty(result) && continue

        r = split(result, ',')
        test = r[2]
        time = parse(r[5])

        monster.results_micro[test] = time
        monster.fitness += time
    end

    println("results: ", monster.results_micro)
    monster.fitness
end

function group_entities(pop)
    if generation_num() > 2048
        return
    end

    elite_selection(pop, 1)

    tournament_selection(pop, 2)
end

function crossover(parents)
    length(parents) == 1 && return parents[1]
end

function mutate(monster)
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

end

# -------

using GeneticAlgorithms

println("Running GA!")

model = runga(PassGA; initial_pop_size = 3)

println(population(model))
