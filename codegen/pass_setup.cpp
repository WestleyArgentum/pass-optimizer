
#include <fstream>
#include <sstream>
#include <string>
#include <map>

// Super simple version of delegates, for handling
// passes with different return values

class Delegate {
public:
    virtual ~Delegate() {}
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

template <typename Ret>
Delegate* wrap_fn(Ret (*fn)()) {
    return new SpecialReturnDelegate<Ret>(fn);
}

// -------

void setup_passes_from_file(FunctionPassManager* FPM, const char* pass_file_name) {
    jl_printf(JL_STDOUT, "applying llvm passes from file: %s\n", pass_file_name);

    // create a map of pass functions, for convenience
    std::map<std::string, Delegate*> ir_passes;
    ir_passes["createCFGSimplificationPass"] = wrap_fn(llvm::createCFGSimplificationPass);
    ir_passes["createLICMPass"] = wrap_fn(llvm::createLICMPass);

    std::ifstream pass_file(pass_file_name);
    std::string pass_name;
    while (std::getline(pass_file, pass_name)) {
        jl_printf(JL_STDOUT, "applying pass: %s\n", pass_name.c_str());
        FPM->add((*ir_passes[pass_name])());
    }

    // clean up our pass function delegates so that we don't leak
    for (std::map<std::string, Delegate*>::iterator i = ir_passes.begin(); i != ir_passes.end(); ++i) {
        delete i->second;
    }
}
