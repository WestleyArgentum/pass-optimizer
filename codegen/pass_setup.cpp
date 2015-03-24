
#include <fstream>
#include <sstream>
#include <string>
#include <map>

void setup_passes_from_file(FunctionPassManager* FPM, const char* pass_file_name) {
    jl_printf(JL_STDOUT, "applying llvm passes from file: %s\n", pass_file_name);

    std::map<std::string, FunctionPass* (*)()> ir_passes;
    ir_passes["createCFGSimplificationPass"] = llvm::createCFGSimplificationPass;

    std::ifstream pass_file(pass_file_name);
    std::string pass_name;
    while (std::getline(pass_file, pass_name)) {
        jl_printf(JL_STDOUT, "applying pass: %s\n", pass_name.c_str());
        FPM->add(ir_passes[pass_name]());
    }
}
