
#include <fstream>
#include <sstream>
#include <string>
#include <map>

// Super simple version of delegates, for handling
// passes with different return values

class Delegate {
public:
    virtual llvm::Pass* operator () () = 0;
};

template <typename Ret>
class SpecialReturnDelegate: public Delegate {
public:
    typedef Ret (*fn_ptr)();

    SpecialReturnDelegate(fn_ptr _fn) : fn(_fn) {}

    virtual llvm::Pass* operator () () {
        return fn();
    }

private:
    fn_ptr fn;
};

// -------

void setup_passes_from_file(FunctionPassManager* FPM, const char* pass_file_name) {
    jl_printf(JL_STDOUT, "applying llvm passes from file: %s\n", pass_file_name);

    std::map<std::string, Delegate*> ir_passes;
    ir_passes["createCFGSimplificationPass"] = new SpecialReturnDelegate<llvm::FunctionPass*>(llvm::createCFGSimplificationPass);
    ir_passes["createLICMPass"] = new SpecialReturnDelegate<llvm::Pass*>(llvm::createLICMPass);

    std::ifstream pass_file(pass_file_name);
    std::string pass_name;
    while (std::getline(pass_file, pass_name)) {
        jl_printf(JL_STDOUT, "applying pass: %s\n", pass_name.c_str());
        FPM->add((*ir_passes[pass_name])());
    }
}
