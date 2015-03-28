
module PassGA

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

    PassMonster() = new(Array(String, 1), nothing)
    PassMonster(passes::Array{String, 1}) = new(passes, nothing)
end

function create_entity(num)
    monster = PassMonster()

    num_passes = rand(1:50)
    for i in 1:num_passes
        push!(monster.passes, passes[rand(1:length(passes))])
    end

    monster
end

function fitness(monster)
end

function group_entities(pop)
end

function crossover(group)
end

function mutate(monster)
end

end

# -------

using GeneticAlgorithms

println("Running GA!")

model = runga(PassGA; initial_pop_size = 64)

println(population(model))
