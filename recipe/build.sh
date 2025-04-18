#!/usr/bin/env bash

set -ex

ARCH_ARGS=""
if [ "$(uname)" == "Darwin" ]; then
    #CXXFLAGS="-D_LIBCPP_ENABLE_CXX17_REMOVED_UNARY_BINARY_FUNCTION=1 ${CXXFLAGS}"
    CXXFLAGS="${CXXFLAGS} -std=c++14"
fi

${BUILD_PREFIX}/bin/cmake ${CMAKE_ARGS} ${ARCH_ARGS} \
  -G "Ninja" \
  -S ${SRC_DIR} \
  -B build \
  -D CMAKE_INSTALL_PREFIX=${PREFIX} \
  -D CMAKE_BUILD_TYPE=Release \
  -D CMAKE_C_COMPILER=${CC} \
  -D CMAKE_C_FLAGS="${CFLAGS}" \
  -D CMAKE_CXX_COMPILER=${CXX} \
  -D CMAKE_CXX_FLAGS="${CXXFLAGS}" \
  -D CMAKE_Fortran_COMPILER=${FC} \
  -D CMAKE_Fortran_FLAGS="${FFLAGS}" \
  -D CMAKE_INSTALL_LIBDIR=lib \
  -D PYMOD_INSTALL_LIBDIR="/python${PY_VER}/site-packages" \
  -D Python_EXECUTABLE=${PYTHON} \
  -D EIGEN3_ROOT=${PREFIX} \
  -D ENABLE_OPENMP=OFF \
  -D ENABLE_GENERIC=OFF \
  -D ENABLE_TESTS=ON \
  -D ENABLE_TIMER=OFF \
  -D ENABLE_LOGGER=OFF \
  -D BUILD_STANDALONE=ON \
  -D ENABLE_CXX11_SUPPORT=ON

# using make b/c VersionInfo suddenly not getting generated in time on Linux with Ninja
#   so pre-building as need to use Ninja for Windows (NMake has another error)
cmake --build build --target update_version
cmake --build build --target install -j${CPU_COUNT}

# Building both static & shared (instead of SHARED_LIBRARY_ONLY) since the tests
#   only build with static lib. Don't want to distribute static, though, so
#   removing all the static lib stuff immediately after install.
rm ${PREFIX}/share/cmake/PCMSolver/PCMSolverTargets-static-release.cmake
rm ${PREFIX}/share/cmake/PCMSolver/PCMSolverTargets-static.cmake
rm ${PREFIX}/lib/libpcm.a

cd build
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR}" != "" ]]; then
if [[ "$target_platform" == "linux-aarch64" || "$target_platform" == "linux-ppc64le" || "$target_platform" == "linux-64" ]]; then
    ctest --rerun-failed --output-on-failure -j${CPU_COUNT} -E 'SPD|gauss-failure|green_spherical_diffuse'
    # green_spherical_diffuse excluded b/c failing on aarch64 and long duration for emulated
    # green_spherical_diffuse on linux-64 works fine locally but suddenly (Apr 2025) fails with no output. still tested on osx-64
else
    ctest --rerun-failed --output-on-failure -j${CPU_COUNT} -E 'SPD|gauss-failure'
    # SPD-failure test excluded after patch 0005 that commutes the fail
    # gauss-failure test exluded after patch 0007 that commutes the fail
fi
fi

