
module PassGA

using GeneticAlgorithms

type PassMonster <: Entity
    passes::Array{String, 1}
    fitness
end

function create_entity(num)
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
