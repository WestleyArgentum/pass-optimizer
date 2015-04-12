#!/bin/sh

JULIA_DIR="./julia"

if [ ! -d "$JULIA_DIR" ]; then
    git clone https://github.com/JuliaLang/julia.git $JULIA_DIR
fi

ln -sf ../../codegen/pass_setup.cpp $JULIA_DIR/src/pass_setup.cpp
ln -sf ../../codegen/codegen.cpp $JULIA_DIR/src/codegen.cpp

cd $JULIA_DIR
make
