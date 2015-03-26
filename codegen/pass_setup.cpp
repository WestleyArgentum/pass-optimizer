
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
class Delegate0: public Delegate {
public:
    typedef Ret (*fn_ptr)();

    Delegate0(fn_ptr _fn) : fn(_fn) {}

    virtual llvm::Pass* operator () () {
        return fn();
    }

private:
    fn_ptr fn;
};

template <typename Ret>
Delegate* wrap_fn(Ret (*fn)()) {
    return new Delegate0<Ret>(fn);
}


// Special cases that can't be wrapped by delegates because they
// have default parameters that are hard to encode in fn pointers

inline llvm::Pass* _createAddressSanitizerFunctionPass() {
    return llvm::createAddressSanitizerFunctionPass();
}

inline llvm::Pass* _createGVNPass() {
    return llvm::createGVNPass();
}

inline llvm::Pass* _createLoopUnrollPass() {
    return llvm::createLoopUnrollPass();
}

inline llvm::Pass* _createLoopUnswitchPass() {
    return llvm::createLoopUnswitchPass();
}

inline llvm::Pass* _createScalarReplAggregatesPass() {
    return llvm::createScalarReplAggregatesPass();
}

// -------


void setup_passes_from_file(FunctionPassManager* FPM, const char* pass_file_name) {
    jl_printf(JL_STDOUT, "applying llvm passes from file: %s\n", pass_file_name);

    // create a map of pass functions, for convenience
    std::map<std::string, Delegate*> ir_passes;
    ir_passes["createAddressSanitizerFunctionPass"] = wrap_fn(_createAddressSanitizerFunctionPass);
    ir_passes["createTypeBasedAliasAnalysisPass"] =   wrap_fn(llvm::createTypeBasedAliasAnalysisPass);
    ir_passes["createBasicAliasAnalysisPass"] =       wrap_fn(llvm::createBasicAliasAnalysisPass);
    ir_passes["createCFGSimplificationPass"] =        wrap_fn(llvm::createCFGSimplificationPass);
    ir_passes["createPromoteMemoryToRegisterPass"] =  wrap_fn(llvm::createPromoteMemoryToRegisterPass);
    ir_passes["createInstructionCombiningPass"] =     wrap_fn(llvm::createInstructionCombiningPass);
    ir_passes["createScalarReplAggregatesPass"] =     wrap_fn(_createScalarReplAggregatesPass);
    ir_passes["createJumpThreadingPass"] =            wrap_fn(llvm::createJumpThreadingPass);
    ir_passes["createReassociatePass"] =              wrap_fn(llvm::createReassociatePass);
    ir_passes["createEarlyCSEPass"] =                 wrap_fn(llvm::createEarlyCSEPass);
    ir_passes["createLoopIdiomPass"] =                wrap_fn(llvm::createLoopIdiomPass);
    ir_passes["createLoopRotatePass"] =               wrap_fn(llvm::createLoopRotatePass);
    ir_passes["createLowerSimdLoopPass"] =            wrap_fn(llvm::createLowerSimdLoopPass);
    ir_passes["createLICMPass"] =                     wrap_fn(llvm::createLICMPass);
    ir_passes["createLoopUnswitchPass"] =             wrap_fn(_createLoopUnswitchPass);
    ir_passes["createIndVarSimplifyPass"] =           wrap_fn(llvm::createIndVarSimplifyPass);
    ir_passes["createLoopDeletionPass"] =             wrap_fn(llvm::createLoopDeletionPass);
    ir_passes["createLoopUnrollPass"] =               wrap_fn(_createLoopUnrollPass);
    ir_passes["createLoopVectorizePass"] =            wrap_fn(llvm::createLoopVectorizePass);
    ir_passes["createGVNPass"] =                      wrap_fn(_createGVNPass);
    ir_passes["createSCCPPass"] =                     wrap_fn(llvm::createSCCPPass);
    ir_passes["createSinkingPass"] =                  wrap_fn(llvm::createSinkingPass);
    ir_passes["createInstructionSimplifierPass"] =    wrap_fn(llvm::createInstructionSimplifierPass);
    ir_passes["createDeadStoreEliminationPass"] =     wrap_fn(llvm::createDeadStoreEliminationPass);
    ir_passes["createSLPVectorizerPass"] =            wrap_fn(llvm::createSLPVectorizerPass);
    ir_passes["createAggressiveDCEPass"] =            wrap_fn(llvm::createAggressiveDCEPass);

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
