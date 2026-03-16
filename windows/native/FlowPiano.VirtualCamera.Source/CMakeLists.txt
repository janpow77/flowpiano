cmake_minimum_required(VERSION 3.28)

project(FlowPianoVirtualCameraSource LANGUAGES CXX)

add_library(FlowPianoVirtualCameraSource SHARED
    FlowPianoVirtualCameraSource.cpp
    FlowPianoVirtualCameraSource.def
)

target_compile_features(FlowPianoVirtualCameraSource PRIVATE cxx_std_20)
target_compile_definitions(FlowPianoVirtualCameraSource PRIVATE UNICODE _UNICODE WIN32_LEAN_AND_MEAN NOMINMAX)
target_include_directories(FlowPianoVirtualCameraSource PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(FlowPianoVirtualCameraSource PRIVATE ole32 uuid)

set_target_properties(FlowPianoVirtualCameraSource PROPERTIES
    OUTPUT_NAME "FlowPianoVirtualCameraSource"
)

install(TARGETS FlowPianoVirtualCameraSource
    RUNTIME DESTINATION FlowPiano.VirtualCamera.Source
    LIBRARY DESTINATION FlowPiano.VirtualCamera.Source
    ARCHIVE DESTINATION FlowPiano.VirtualCamera.Source
)
