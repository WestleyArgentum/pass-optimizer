This is a testbed where I'm experimenting with ways to optimize the llvm ir passes used to generate julia code.

#### Quick start
1. `git clone https://github.com/WestleyArgentum/pass-optimizer.git`
2. `cd pass-optimizer`
3. `git clone https://github.com/JuliaLang/julia.git`
4. `./init.sh`
5. `cd ./julia; make`
6. Now you should be able to start Julia and it will attempt to read `passes.conf` from your current directory.
7. 
