cmake_minimum_required(VERSION 3.20)

project(llvm_build VERSION 2025.0.0)

# Add a custom target to run install.sh
add_custom_target(
  run_install
  COMMAND ${CMAKE_COMMAND} -E env bash ${CMAKE_SOURCE_DIR}/scripts/install.sh
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  COMMENT "Running install.sh"
  VERBATIM USES_TERMINAL)

# Add an install step to run the custom install target with output
# synchronization
install(
  CODE "execute_process(COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target run_install)"
)
