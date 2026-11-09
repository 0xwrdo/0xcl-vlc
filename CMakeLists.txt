cmake_minimum_required(VERSION 3.21)
project(Modern0xcl VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)

# ---------------- libvlc ----------------
if(WIN32)
    # Unzip vlc-3.0.x-win64.zip somewhere and point VLC_SDK_DIR at the extracted vlc-3.0.x folder
    set(VLC_SDK_DIR "" CACHE PATH "Extracted VLC 3.0.x win64 folder (contains libvlc.dll, plugins/, sdk/)")
    find_path(VLC_INCLUDE_DIR vlc/vlc.h HINTS "${VLC_SDK_DIR}/sdk/include" REQUIRED)
    find_library(VLC_LIBRARY NAMES libvlc HINTS "${VLC_SDK_DIR}/sdk/lib" REQUIRED)
    find_library(VLCCORE_LIBRARY NAMES libvlccore HINTS "${VLC_SDK_DIR}/sdk/lib" REQUIRED)
    set(VLC_LIBS ${VLC_LIBRARY} ${VLCCORE_LIBRARY})
else()
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(LIBVLC REQUIRED libvlc)
    set(VLC_INCLUDE_DIR ${LIBVLC_INCLUDE_DIRS})
    set(VLC_LIBS ${LIBVLC_LINK_LIBRARIES})
endif()

# ---------------- QML + assets embedded as resources (qrc:/qml/...) ----------------
file(GLOB QML_FILES RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS qml/*.qml qml/*.png)
set_source_files_properties(packaging/0xcl-256.png PROPERTIES QT_RESOURCE_ALIAS icons/0xcl.png)

set(SOURCES src/main.cpp src/models.cpp src/models.h src/realvideosurface.cpp src/realvideosurface.h)
if(WIN32)
    list(APPEND SOURCES src/app.rc)
endif()

qt_add_executable(0xcl WIN32 ${SOURCES})
qt_add_resources(0xcl "app_resources" PREFIX "/" FILES ${QML_FILES} packaging/0xcl-256.png)

target_include_directories(0xcl PRIVATE ${VLC_INCLUDE_DIR})
target_link_libraries(0xcl PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::QuickControls2 ${VLC_LIBS})
if(MSVC)
    target_compile_options(0xcl PRIVATE /utf-8)
    target_compile_definitions(0xcl PRIVATE NOMINMAX _CRT_SECURE_NO_WARNINGS)
endif()

# Copy VLC runtime next to the exe so it can be launched straight from the build folder
if(WIN32)
    add_custom_command(TARGET 0xcl POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${VLC_SDK_DIR}/libvlc.dll" "${VLC_SDK_DIR}/libvlccore.dll" $<TARGET_FILE_DIR:0xcl>
        COMMAND ${CMAKE_COMMAND} -E copy_directory "${VLC_SDK_DIR}/plugins" $<TARGET_FILE_DIR:0xcl>/plugins)
endif()

install(TARGETS 0xcl RUNTIME DESTINATION .)
