add_library(buildlab_core core.c)
add_library(buildlab::core ALIAS buildlab_core)

# EXPORT_NAME makes the post-install imported target match the in-tree
# ALIAS spelling (buildlab::core) instead of namespacing the raw target
# name (which would otherwise become buildlab::buildlab_core).
set_target_properties(buildlab_core PROPERTIES EXPORT_NAME core)

target_include_directories(buildlab_core
    PUBLIC
        $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

target_compile_features(buildlab_core PUBLIC c_std_11)

# Wrapped in $<BUILD_INTERFACE:...> so these build-only flag carriers never
# need to be part of the installed export set (a STATIC library otherwise
# requires every PRIVATE link dependency to be exported alongside it).
target_link_libraries(buildlab_core
    PRIVATE
        $<BUILD_INTERFACE:buildlab_project_options>
        $<BUILD_INTERFACE:buildlab_project_warnings>
)
