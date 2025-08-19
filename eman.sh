#!/usr/bin/env bash
set -euo pipefail

check_verilator() {
    echo "==== Verilator Check ===="
    if command -v verilator >/dev/null 2>&1; then
        verilator --version
    else
        echo "Verilator not found in PATH"
    fi
    echo
}

c_compiler_version() {
    echo "==== C Compiler & Make Version ===="
    if command -v gcc >/dev/null 2>&1; then
        gcc --version | head -n1
    else
        echo "GCC not found"
    fi

    if command -v make >/dev/null 2>&1; then
        make --version | head -n1
    else
        echo "GNU Make not found"
    fi
    echo
}

check_tool() {
    local tool="$1"
    local version_arg="${2:---version}"

    echo "==== $tool Check ===="
    if command -v "$tool" >/dev/null 2>&1; then
        "$tool" $version_arg | head -n1 || echo "$tool installed (no version output)"
    else
        echo "$tool not found in PATH"
    fi
    echo
}

check_conda() {
    echo "==== Conda Check ===="
    if command -v conda >/dev/null 2>&1; then
        conda --version
    else
        echo "conda not found in PATH"
    fi
    echo
}

check_ca_certificates() {
    echo "==== ca-certificates Check ===="
    if dpkg -s ca-certificates >/dev/null 2>&1; then
        echo "ca-certificates installed"
    else
        echo "ca-certificates not installed"
    fi
    echo
}

check_verilator
c_compiler_version
check_tool curl
check_tool wget
check_ca_certificates
check_tool vim --version
check_tool git
check_conda
