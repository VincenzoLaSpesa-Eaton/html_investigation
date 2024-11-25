cmake_minimum_required (VERSION 3.20)
#set(CMAKE_FIND_DEBUG_MODE 1)

project(StupidBrowser VERSION 3 LANGUAGES C CXX)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${PROJECT_SOURCE_DIR}/cmake")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)


if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
	MESSAGE(STATUS "No toolchain is defined")
else()
	MESSAGE(STATUS "Using toolchain in ${CMAKE_TOOLCHAIN_FILE}")
endif()

if(CMAKE_SIZEOF_VOID_P EQUAL 8)
	set(OBT_64 ON)
	MESSAGE( STATUS "Running on x64")
else()
	set(OBT_32 ON)
	MESSAGE( STATUS "Running on x86")
endif()

set (CMAKE_CXX_STANDARD 17)

MESSAGE( STATUS "Looking for libs ... " )
# some common libs
  find_package(RmlUi REQUIRED)
  #find_package(Boost REQUIRED)
  #find_package(asio REQUIRED)
  #find_package(SFML COMPONENTS graphics window REQUIRED)
  
  #find_package(Threads REQUIRED )
  #MESSAGE(STATUS "--> Pthread in " ${CMAKE_THREAD_LIBS_INIT})#pthread library
  
MESSAGE( STATUS "All libs found. " )

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)


set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

set(PROJECT_INSTALL_DIR "bin")

add_executable(StupidBrowser_t 
	./src/main.cpp
)

target_include_directories(StupidBrowser_t PRIVATE "${base_folder}/RmlUi/Include")
target_link_libraries(StupidBrowser_t RmlUi::RmlUi)

