@ECHO ON

:: Use C++ 14 instead of C++11
sed -i 's/CMAKE_CXX_STANDARD 11/CMAKE_CXX_STANDARD 14/' cmake\custom\compilers\CXXFlags.cmake

cmake %CMAKE_ARGS% ^
  -G "MinGW Makefiles" ^
  -S %SRC_DIR% ^
  -B build ^
  -D CMAKE_C_COMPILER=%CC% ^
  -D CMAKE_CXX_COMPILER=%CXX% ^
  -D CMAKE_Fortran_COMPILER=%FC% ^
  -D CMAKE_BUILD_TYPE=Release ^
  -D PYMOD_INSTALL_LIBDIR="/Library/lib/python3.12/site-packages" ^
  -D Python_EXECUTABLE="%PYTHON%" ^
  -D EIGEN3_ROOT="%LIBRARY_PREFIX%" ^
  -D CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS=ON ^
  -D CMAKE_GNUtoMS=ON ^
  -D BUILD_TESTING=OFF ^
  -D ENABLE_OPENMP=OFF ^
  -D ENABLE_GENERIC=OFF ^
  -D ENABLE_TESTS=ON ^
  -D ENABLE_TIMER=OFF ^
  -D ENABLE_LOGGER=OFF ^
  -D BUILD_STANDALONE=ON ^
  -D ENABLE_CXX11_SUPPORT=ON
if errorlevel 1 exit 1

cmake --build build ^
      --config Release ^
      --target install ^
      -- -j %CPU_COUNT%
if errorlevel 1 exit 1

:: Building both static & shared (instead of SHARED_LIBRARY_ONLY) since the tests
::   only build with static lib. Don't want to distribute static, though, so
::   removing all the static lib stuff immediately after install.
del %LIBRARY_PREFIX%\\share\\cmake\\PCMSolver\\PCMSolverTargets-static-release.cmake
del %LIBRARY_PREFIX%\\share\\cmake\\PCMSolver\\PCMSolverTargets-static.cmake
del %LIBRARY_PREFIX%\\lib\\libpcm.a

cd build
ctest --rerun-failed --output-on-failure -E "SPD|gauss-failure"
:: SPD-failure test excluded after patch 0005 that commutes the fail
if errorlevel 1 exit 1
