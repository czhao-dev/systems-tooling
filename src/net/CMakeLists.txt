add_library(buildlab_net net.cpp)
add_library(buildlab::net ALIAS buildlab_net)

# See src/core/CMakeLists.txt for why EXPORT_NAME is set explicitly.
set_target_properties(buildlab_net PROPERTIES EXPORT_NAME net)

target_include_directories(buildlab_net
    PUBLIC
        $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

target_compile_features(buildlab_net PUBLIC cxx_std_17)

# See src/core/CMakeLists.txt for why these are wrapped in $<BUILD_INTERFACE:...>.
target_link_libraries(buildlab_net
    PRIVATE
        $<BUILD_INTERFACE:buildlab_project_options>
        $<BUILD_INTERFACE:buildlab_project_warnings>
)
