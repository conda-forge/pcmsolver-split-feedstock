#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

# Use C++ 14 instead of C++11
sed -i 's/CMAKE_CXX_STANDARD 11/CMAKE_CXX_STANDARD 14/' cmake/custom/compilers/CXXFlags.cmake

cmake ${CMAKE_ARGS} \
  -S ${SRC_DIR} \
  -B build \
  -D CMAKE_VERBOSE_MAKEFILE=ON \
  -D CMAKE_BUILD_TYPE=Release \
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
#  -G "Ninja"
cmake --build build --target install -j${CPU_COUNT}

# Building both static & shared (instead of SHARED_LIBRARY_ONLY) since the tests
#   only build with static lib. Don't want to distribute static, though, so
#   removing all the static lib stuff immediately after install.
rm ${PREFIX}/share/cmake/PCMSolver/PCMSolverTargets-static-release.cmake
rm ${PREFIX}/share/cmake/PCMSolver/PCMSolverTargets-static.cmake
rm ${PREFIX}/lib/libpcm.a

cd build
if [[ "${CONDA_BUILD_CROSS_COMPILATION:-}" != "1" || "${CROSSCOMPILING_EMULATOR:-}" != "" ]]; then
    ctest --rerun-failed --output-on-failure -j${CPU_COUNT} -E 'SPD|gauss-failure|green_spherical_diffuse'
fi

