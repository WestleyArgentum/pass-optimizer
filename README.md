## IR Pass Optimizer

This is an ongoing project that uses a genetic algorithm to optimize the layout of LLVM IR passes used to compile Julia code.

### Quick start
1. `git clone https://github.com/WestleyArgentum/pass-optimizer.git`
2. `cd pass-optimizer`
3. `./init.sh`
4. `julia pass-ga.jl`


## Design of the GA

### Crossover

Many traditional methods of crossover (single and double point, uniform) assume a genome of a fixed length, or some knowledge about what the optimal length might be. Others support variable length genomes (messy ga, SAGA), but pick largely random points when splicing parent sequences together.

The algorithm employed by this GA is called "Synapsing Variable Length Crossover". It uses the longest common subsequence to identify and split parents genomes in a way that preserves the order and content of the lcs shared by both parents. The paper that formally describes SVLC is [behind a paywall](http://ieeexplore.ieee.org/xpl/login.jsp?tp=&arnumber=4079615&url=http%3A%2F%2Fieeexplore.ieee.org%2Fiel5%2F4235%2F4079606%2F04079615.pdf%3Farnumber%3D4079615), but you can read some [here](https://books.google.com/books?id=3haO5vOc12cC&pg=PA198&lpg=PA198&ots=xIjc04cd22&sig=gzUjpqLzEy9w2VLtawMTs9TQ9_Q&hl=en&sa=X&ei=nkIjVdqDF4edsAWFpoGgBg&ved=0CFsQ6AEwBw#v=onepage) and the code in this repository represents my attempt at an accurate reproduction.


### Mutation

Because this GA relies on variable length genomes, it's important for the mutation function to sometimes insert and remove genes, in addition to simply changing them in place. Right now this is done very agressively at first (with a large number of passes being added / removed / changed), and less agressively over time until the GA has reached a predefined `MAX_GENERATIONS` and stops.


## Areas for improvement

Please see the [open issues](https://github.com/WestleyArgentum/pass-optimizer/issues) for information about planned improvments / known problems.
