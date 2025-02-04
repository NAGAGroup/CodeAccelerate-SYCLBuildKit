cmake_minimum_required(VERSION 3.20)

project(llvm_build VERSION 2025.0.0)

# Add a custom target to run configure.sh
add_custom_target(
  run_configure
  COMMAND ${CMAKE_COMMAND} -E env DPCPP_HOME=${CMAKE_SOURCE_DIR} bash
          ${CMAKE_SOURCE_DIR}/scripts/configure.sh
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  COMMENT "Running configure.sh"
  VERBATIM USES_TERMINAL)

# Add a custom target to run install.sh
add_custom_target(
  run_install
  COMMAND ${CMAKE_COMMAND} -E env DPCPP_HOME=${CMAKE_SOURCE_DIR} bash
          ${CMAKE_SOURCE_DIR}/scripts/install.sh
  WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
  COMMENT "Running install.sh"
  VERBATIM USES_TERMINAL)

add_dependencies(run_install run_configure)

# Add an install step to run the custom install target with output
# synchronization
install(
  CODE "execute_process(COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target run_install)"
)
