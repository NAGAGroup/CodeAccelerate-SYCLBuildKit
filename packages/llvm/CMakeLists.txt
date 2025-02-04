cmake_minimum_required(VERSION 3.20)

project(llvm_build VERSION 2025.0.0)

# Top-level execute_process to remove the output files
execute_process(
  COMMAND ${CMAKE_COMMAND} -E env rm -f ${CMAKE_SOURCE_DIR}/build/CMakeCache.txt
          ${CMAKE_SOURCE_DIR}/build/install.stamp
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/build)

# Execute the configure.sh script
execute_process(
  COMMAND ${CMAKE_COMMAND} -E env DPCPP_HOME=${CMAKE_SOURCE_DIR} bash
          ${CMAKE_SOURCE_DIR}/scripts/configure.sh
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})

# Add a custom target to run install.sh
add_custom_target(
  run_install
  COMMAND ${CMAKE_COMMAND} -E env bash ${CMAKE_SOURCE_DIR}/scripts/install.sh
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/build
  COMMENT "Running install.sh"
  VERBATIM)

# Add an install step to run the custom install target
install(
  CODE "execute_process(
    COMMAND ${CMAKE_COMMAND} --build . --target run_install
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}/build
  )")
