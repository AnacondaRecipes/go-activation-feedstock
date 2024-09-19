#!/usr/bin/env bash
set -exuf

if [[ "${CONDA_BUILD_CROSS_COMPILATION:-0}" == "1" && "${CMAKE_CROSSCOMPILING_EMULATOR:-}" == "" ]]; then
  # This is currently only true on osx-arm64
  exit 0
fi

# Test variable is set
test "${CONDA_GO_COMPILER}" == 1


# Test GOBIN is set to $PREFIX/bin
test "$(go env GOBIN)" == "$CONDA_PREFIX/bin"


# Test GOPATH is set to SRC-DIR
# We cannot use that here though as conda-build checks for
# the existence of SRC-DIR for an old behaviour change.
#
# Resolve GOPATH symlinks. This is particularly an issue in
# CI on OSX with /var being a symlink to /private/var.
if [[ "${build_platform:0:3}" == "osx" ]]; then
  gopath=$(go env GOPATH)
  if [[ ! -f "${gopath}" ]]; then
    # readlink doesn't work if the target doesn't exist.
    mkdir -p "${gopath}"
  fi
  test "$(readlink -f ${gopath})" == "${PWD}/gopath"
else
  test "$(go env GOPATH)" == "${PWD}/gopath"
fi


# Print diagnostics
go env

go mod init example.com/hello_world
go build .
if [[ "${cross_target_platform}" == "${build_platform}" || "${CMAKE_CROSSCOMPILING_EMULATOR:-}" != "" ]]; then
  ./hello_world
fi
