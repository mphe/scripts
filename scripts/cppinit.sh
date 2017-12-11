#!/bin/bash

printhelp() {
    echo "Creates a C++ project directory structure."
    echo -e "Usage:\n\t${0##*/} name [options]"
    echo -e "\nOptions:"
    echo -e "\t-h, --help\t\tShow help"
    echo -e "\t-d, --dir <name>\tUse this name for the root directory rather than the project name"
    echo -e "\t-i, --include\t\tCreate a 'include' directory"
    echo -e "\t-g, --git\t\tRun 'git init' and create a .gitignore with the build directory"
    echo -e "\t-c, --cmake\t\tCreate a basic CMakeLists.txt files"
    echo -e "\t-cg, --cmake-gen\tGenerate a Makefile using cmake"
    echo -e "\t-s, --std <version>\tUse this C++ standard, e.g. -s 11 to use c++11."
    echo -e "\t-n, --norequire\t\tDon't require the standard set with -s/--std"
    echo -e "\t--sfml <version>\tSet up an SFML cmake project, e.g. --sfml 2.4"
}

main() {
    if [[ $# -eq 0 ]]; then
        echo "No project name specified."
        exit 1
    elif [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        printhelp
        exit
    fi

    if [[ "${1:0:1}" == "-" ]]; then
        echo "Warning: project name '$1' starts with '-'."
        local ans=
        until [[ ${ans,,} =~ ^[ny]$ ]]; do
            read -n 1 -p "Continue? (y/N) " ans
            echo
        done
        [[ ${ans,,} == "n" ]] && exit
    fi

    NAME="$1"
    UPPERNAME="${NAME^^}"
    INCDIR=src
    STD=
    REQUIRE=ON
    SFML=
    local DIRNAME="$NAME"
    local GITREPO=false
    local CMAKE=false
    local CMAKEGEN=false
    local DIRS=( "src/$NAME" "test" "build/release" "build/debug" "extlib" )

    shift

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help )
                printhelp
                exit
                ;;
            -d|--dir )
                DIRNAME="$2"
                shift
                ;;
            -i|--include )
                DIRS+=( "include/$NAME" )
                INCDIR=include
                ;;
            -g|--git )
                GITREPO=true
                ;;
            -c|--cmake )
                CMAKE=true
                ;;
            -cg|--cmake-gen )
                CMAKEGEN=true
                ;;
            -s|--std )
                STD="$2"
                shift
                ;;
            -n|--norequire )
                REQUIRE=OFF
                ;;
            --sfml )
                SFML="$2"
                shift
                ;;
            * )
                echo "Unknown parameter: $1"
                ;;
        esac
        shift
    done

    mkdir -p -- "$DIRNAME"
    cd "$DIRNAME"
    for i in "${DIRS[@]}"; do
        mkdir -p -- "$i"
    done

    maincpp > "src/$NAME/main.cpp"

    if $GITREPO; then
        git init
        gitignore > .gitignore
    fi

    if $CMAKE; then
        mkdir -p cmake/Modules
        cmake_main > CMakeLists.txt
        cmake_src > "src/$NAME/CMakeLists.txt"
        cmake_test > test/CMakeLists.txt
        echo "" > extlib/CMakeLists.txt

        if $CMAKEGEN; then
            cd build/debug
            cmake -DCMAKE_BUILD_TYPE=Debug ../..
            cd ../release
            cmake -DCMAKE_BUILD_TYPE=Release ../..
        fi
    fi
}

gitignore() {
    echo -e "build/"
}

# Creates the main CMakeLists.txt
cmake_main() {
    echo -e "cmake_minimum_required(VERSION 2.6)
project(\"$NAME\")

# Options {{{
set(CMAKE_MODULE_PATH \${CMAKE_MODULEPATH} \"\${CMAKE_SOURCE_DIR}/cmake/Modules/\")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY \${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY \${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY \${CMAKE_BINARY_DIR}/lib)"

[[ -n "$SFML" ]] && echo -e "
set(SFML_ROOT \"\" CACHE PATH \"SFML library directory (optional)\")"

echo -e "
option(${UPPERNAME}_BUILD_TESTS \"Build tests\" ON)
option(USE_CCACHE \"Use ccache if available\" ON)

# Enable warnings and colored compiler output
if (CMAKE_COMPILER_IS_GNUCC)
    add_definitions(-Wall -Wno-switch -fdiagnostics-color=auto)
elseif (MSVC)
    # Untested
    add_definitions(/W3)
endif()

# Use ccache if available
if(USE_CCACHE)
    find_program(CCACHE_FOUND ccache)
    if(CCACHE_FOUND)
        set_property(GLOBAL PROPERTY RULE_LAUNCH_COMPILE ccache)
        set_property(GLOBAL PROPERTY RULE_LAUNCH_LINK ccache)
    endif(CCACHE_FOUND)
endif(USE_CCACHE)

# }}} Options"

[[ -n "$SFML" ]] && echo -e "
# sfml
find_package(SFML $SFML COMPONENTS system window graphics REQUIRED)
include_directories(\${SFML_INCLUDE_DIR})"

echo -e "
add_subdirectory(\"extlib\")
add_subdirectory(\"src/$NAME\")

if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(test)
endif()"
}

# Creates the CMakeLists.txt for the src directory
cmake_src() {
    echo -e "set(CXX_STANDARD_REQUIRED $REQUIRE)

set(PROJECT_SOURCES
    main.cpp
)

set(EXT_LIBRARIES
    $([[ -n "$SFML" ]] && echo -ne "\${SFML_LIBRARIES}")
)

source_group(\${PROJECT_NAME} FILES \${PROJECT_SOURCES})

include_directories(
    \${PROJECT_SOURCE_DIR}/$INCDIR
)

add_executable(\${PROJECT_NAME} \${PROJECT_SOURCES})
target_link_libraries(\${PROJECT_NAME} \${EXT_LIBRARIES})
$([[ -n $STD ]] && echo -ne "set_property(TARGET \${PROJECT_NAME} PROPERTY CXX_STANDARD $STD)")

add_custom_target(run
    COMMAND \${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/\${PROJECT_NAME}
    DEPENDS \${PROJECT_NAME}
    WORKING_DIRECTORY \${CMAKE_SOURCE_DIR}
)"
}

# Creates the CMakeLists.txt for the test directory
# arg1: include dir (path)
# arg2: standard (optional)
cmake_test() {
    echo -e "set(CXX_STANDARD_REQUIRED $REQUIRE)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY \${CMAKE_BINARY_DIR}/bin/test)

macro(gen_test TESTNAME SOURCE)
    add_executable(\${TESTNAME} \${SOURCE} \${ARGN})
    add_test(NAME \${TESTNAME} COMMAND \${TESTNAME})"
[[ -n $STD ]] && echo -e "    set_property(TARGET \${TESTNAME} PROPERTY CXX_STANDARD $STD)"
echo -ne "endmacro()

include_directories(
    \${PROJECT_SOURCE_DIR}/$INCDIR
)"
}

# Creates the main.cpp
maincpp() {
    echo "#include <iostream>

using namespace std;

int main(int argc, char** argv)
{
    cout<<\"Hello World\\n\";
    return 0;
}"
}

main "$@"
