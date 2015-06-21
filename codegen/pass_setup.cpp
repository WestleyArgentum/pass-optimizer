
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

inline llvm::Pass* _createSROAPass () {
    return llvm::createSROAPass();
}

inline llvm::Pass* _createSeparateConstOffsetFromGEPPass () {
    return llvm::createSeparateConstOffsetFromGEPPass();
}

// -------


void setup_passes_from_file(FunctionPassManager* FPM, const char* pass_file_name) {
    //jl_printf(JL_STDOUT, "applying llvm passes from file: %s\n", pass_file_name);

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

    ir_passes["createConstantPropagationPass"] = wrap_fn(llvm::createConstantPropagationPass);
    ir_passes["createAlignmentFromAssumptionsPass"] = wrap_fn(llvm::createAlignmentFromAssumptionsPass);
    ir_passes["createDeadInstEliminationPass"] = wrap_fn(llvm::createDeadInstEliminationPass);
    ir_passes["createDeadCodeEliminationPass"] = wrap_fn(llvm::createDeadCodeEliminationPass);
    ir_passes["createBitTrackingDCEPass"] = wrap_fn(llvm::createBitTrackingDCEPass);
    ir_passes["createSROAPass"] = wrap_fn(_createSROAPass);
    ir_passes["createInductiveRangeCheckEliminationPass"] = wrap_fn(llvm::createInductiveRangeCheckEliminationPass);
    ir_passes["createLoopInterchangePass"] = wrap_fn(llvm::createLoopInterchangePass);
    ir_passes["createLoopStrengthReducePass"] = wrap_fn(llvm::createLoopStrengthReducePass);
    ir_passes["createLoopInstSimplifyPass"] = wrap_fn(llvm::createLoopInstSimplifyPass);
    ir_passes["createSimpleLoopUnrollPass"] = wrap_fn(llvm::createSimpleLoopUnrollPass);
    ir_passes["createLoopRerollPass"] = wrap_fn(llvm::createLoopRerollPass);
    ir_passes["createFlattenCFGPass"] = wrap_fn(llvm::createFlattenCFGPass);
    ir_passes["createStructurizeCFGPass"] = wrap_fn(llvm::createStructurizeCFGPass);
    ir_passes["createTailCallEliminationPass"] = wrap_fn(llvm::createTailCallEliminationPass);
    ir_passes["createMergedLoadStoreMotionPass"] = wrap_fn(llvm::createMergedLoadStoreMotionPass);
    ir_passes["createMemCpyOptPass"] = wrap_fn(llvm::createMemCpyOptPass);
    ir_passes["createConstantHoistingPass"] = wrap_fn(llvm::createConstantHoistingPass);
    ir_passes["createLowerAtomicPass"] = wrap_fn(llvm::createLowerAtomicPass);
    ir_passes["createCorrelatedValuePropagationPass"] = wrap_fn(llvm::createCorrelatedValuePropagationPass);
    ir_passes["createLowerExpectIntrinsicPass"] = wrap_fn(llvm::createLowerExpectIntrinsicPass);
    ir_passes["createPartiallyInlineLibCallsPass"] = wrap_fn(llvm::createPartiallyInlineLibCallsPass);
    ir_passes["createSampleProfileLoaderPass"] = wrap_fn(llvm::createSampleProfileLoaderPass);
    ir_passes["createScalarizerPass"] = wrap_fn(llvm::createScalarizerPass);
    ir_passes["createAddDiscriminatorsPass"] = wrap_fn(llvm::createAddDiscriminatorsPass);
    ir_passes["createSeparateConstOffsetFromGEPPass"] = wrap_fn(_createSeparateConstOffsetFromGEPPass);
    ir_passes["createSpeculativeExecutionPass"] = wrap_fn(llvm::createSpeculativeExecutionPass);
    ir_passes["createLoadCombinePass"] = wrap_fn(llvm::createLoadCombinePass);
    ir_passes["createStraightLineStrengthReducePass"] = wrap_fn(llvm::createStraightLineStrengthReducePass);
    ir_passes["createPlaceSafepointsPass"] = wrap_fn(llvm::createPlaceSafepointsPass);
    ir_passes["createRewriteStatepointsForGCPass"] = wrap_fn(llvm::createRewriteStatepointsForGCPass);
    ir_passes["createNaryReassociatePass"] = wrap_fn(llvm::createNaryReassociatePass);
    ir_passes["createLoopDistributePass"] = wrap_fn(llvm::createLoopDistributePass);

    std::ifstream pass_file(pass_file_name);
    std::string pass_name;
    while (std::getline(pass_file, pass_name)) {
        //jl_printf(JL_STDOUT, "applying pass: %s\n", pass_name.c_str());
        FPM->add((*ir_passes[pass_name])());
    }

    // clean up our pass function delegates so that we don't leak
    for (std::map<std::string, Delegate*>::iterator i = ir_passes.begin(); i != ir_passes.end(); ++i) {
        delete i->second;
    }
}
