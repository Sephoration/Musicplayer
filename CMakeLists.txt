cmake_minimum_required(VERSION 3.16)
project(MusicPlayer VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# ---- 查找 Qt6 模块 ----
find_package(Qt6 REQUIRED COMPONENTS
    Core
    Quick
    QuickControls2
    Multimedia
    Gui
    Widgets
    Core5Compat
)

# ---- C++ 源文件 ----
set(SOURCES
    src/main.cpp
    src/app/AppModel.cpp
    src/app/Settings.cpp
    src/audio/AudioEngine.cpp
    src/audio/AudioAnalyzer.cpp
    src/library/LibraryManager.cpp
    src/lyrics/LrcParser.cpp
    src/lyrics/LyricsSync.cpp
)

set(HEADERS
    src/app/AppModel.h
    src/app/Settings.h
    src/audio/AudioEngine.h
    src/audio/AudioAnalyzer.h
    src/library/LibraryManager.h
    src/library/SongModel.h
    src/lyrics/LrcParser.h
    src/lyrics/LyricsSync.h
)

# ---- 资源文件（QML + 图标等） ----
set(RESOURCES
    resources.qrc
)

# ---- 可执行文件 ----
qt_add_executable(MusicPlayer ${SOURCES} ${HEADERS} ${RESOURCES})

# ---- 头文件路径----
target_include_directories(MusicPlayer PRIVATE src)

# ---- 链接库 ----
target_link_libraries(MusicPlayer PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Multimedia
    Qt6::Gui
    Qt6::Widgets
    Qt6::Core5Compat
)

# ---- Windows: 作为 GUI 应用（不弹出控制台） ----
set_target_properties(MusicPlayer PROPERTIES
    WIN32_EXECUTABLE TRUE
)
