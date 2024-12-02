# Copyright (C) 2022 Intel Corporation
# Part of the Unified-Runtime Project, under the Apache License v2.0 with LLVM Exceptions.
# See LICENSE.TXT
# SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception

set(TARGET_NAME ur_adapter_cuda)

add_ur_adapter(${TARGET_NAME}
    SHARED
    ${CMAKE_CURRENT_SOURCE_DIR}/ur_interface_loader.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/adapter.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/adapter.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/command_buffer.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/command_buffer.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/common.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/common.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/context.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/context.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/device.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/device.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/enqueue.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/enqueue_native.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/event.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/event.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/image.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/image.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/kernel.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/kernel.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/memory.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/memory.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/physical_mem.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/physical_mem.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/platform.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/platform.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/program.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/program.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/queue.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/queue.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/sampler.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/sampler.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/tracing.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/usm.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/usm_p2p.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/virtual_mem.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../../ur/ur.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../../ur/ur.hpp
)

set_target_properties(${TARGET_NAME} PROPERTIES
    VERSION "${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}.${PROJECT_VERSION_PATCH}"
    SOVERSION "${PROJECT_VERSION_MAJOR}"
)

find_package(Threads REQUIRED)
find_package(CUDAToolkit 10.1 REQUIRED)

if(UMF_ENABLE_POOL_TRACKING)
  target_compile_definitions("ur_adapter_cuda" PRIVATE UMF_ENABLE_POOL_TRACKING)
else()
  message(WARNING "CUDA adapter USM pools are disabled, set UMF_ENABLE_POOL_TRACKING to enable them")
endif()

if (UR_ENABLE_TRACING)
  if (NOT XPTI_INCLUDES)
    get_target_property(XPTI_INCLUDES xpti INCLUDE_DIRECTORIES)
  endif()
  if (NOT XPTI_PROXY_SRC)
    get_target_property(XPTI_SRC_DIR xpti SOURCE_DIR)
    set(XPTI_PROXY_SRC "${XPTI_SRC_DIR}/xpti_proxy.cpp")
  endif()
  target_compile_definitions(${TARGET_NAME} PRIVATE
    XPTI_ENABLE_INSTRUMENTATION
    XPTI_STATIC_LIBRARY
    )
  target_include_directories(${TARGET_NAME} PUBLIC
    ${XPTI_INCLUDES}
    ${CUDAToolkit_CUPTI_INCLUDE_DIR}
  )
  target_sources(${TARGET_NAME} PRIVATE ${XPTI_PROXY_SRC})
endif()

if (CUDAToolkit_cupti_LIBRARY)
  target_compile_definitions("ur_adapter_cuda" PRIVATE CUPTI_LIB_PATH="${CUDAToolkit_cupti_LIBRARY}")
  list(APPEND EXTRA_LIBS ${CUDAToolkit_cupti_LIBRARY})
endif()

target_link_libraries(${TARGET_NAME} PRIVATE
    ${PROJECT_NAME}::headers
    ${PROJECT_NAME}::common
    ${PROJECT_NAME}::umf
    Threads::Threads
    CUDA::cuda_driver
    ${EXTRA_LIBS}
)

target_include_directories(${TARGET_NAME} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/../../"
)