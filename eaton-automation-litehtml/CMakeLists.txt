cmake_minimum_required (VERSION 3.20)
#set(CMAKE_FIND_DEBUG_MODE 1)

project(StupidBrowser VERSION 3 LANGUAGES C CXX)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${PROJECT_SOURCE_DIR}/cmake")
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(isconan OFF)
set(isvcpkg OFF)


if(NOT DEFINED CMAKE_TOOLCHAIN_FILE)
	MESSAGE(STATUS "No toolchain is defined")
else()
	MESSAGE(STATUS "Using toolchain in ${CMAKE_TOOLCHAIN_FILE}")
	string(REGEX MATCH ".+conan.+" isconan "${CMAKE_TOOLCHAIN_FILE}")
	string(REGEX MATCH ".+vcpkg.+" isvcpkg "${CMAKE_TOOLCHAIN_FILE}")
	if(isconan)
    	message(STATUS "Running with Conan!")
	elseif(isvcpkg)
    	message(STATUS "Running with vcpkg!")
	else()
		message(STATUS "Running with a custom toolchain!")
	endif()	
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

	include(FindPkgConfig)
	find_package(PkgConfig REQUIRED)

	if(isconan)
		find_package(cairo CONFIG REQUIRED)
		find_package(pango CONFIG REQUIRED)
		find_package(SDL2 CONFIG REQUIRED)
	else()
		pkg_check_modules(CAIRO REQUIRED cairo)
		include_directories(${CAIRO_INCLUDE_DIRS})
		
		pkg_check_modules(PANGO REQUIRED pango)
		include_directories(${PANGO_INCLUDE_DIRS})
		
		pkg_check_modules(PANGOCAIRO REQUIRED pangocairo)	
		include_directories(${PANGOCAIRO_INCLUDE_DIRS})
			
		pkg_check_modules(SDL2 REQUIRED sdl2)	
		include_directories(${SDL2_INCLUDE_DIRS})
	endif()
	
	find_package(litehtml REQUIRED)



MESSAGE( STATUS "All libs found. " )

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)


set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set_property(GLOBAL PROPERTY USE_FOLDERS ON)

set(PROJECT_INSTALL_DIR "bin")

set(CONTAINER_PATH "./src/cairo-pango-sdl")

set(SOURCE  ${CONTAINER_PATH}/container_cairo.cpp
            ${CONTAINER_PATH}/cairo_borders.cpp
            ${CONTAINER_PATH}/container_cairo_pango.cpp
    )

set(HEADERS ${CONTAINER_PATH}/container_cairo.h
            ${CONTAINER_PATH}/cairo_borders.h
            ${CONTAINER_PATH}/container_cairo_pango.h
            ${CONTAINER_PATH}/cairo_images_cache.h
        )

add_executable(StupidBrowser_t 
	./src/main.cpp
	./src/web_page.cpp
	${SOURCE}
	${HEADERS}
)

target_include_directories(StupidBrowser_t PRIVATE ${SDL2_INCLUDE_DIRS})

if(isconan)
	target_link_libraries(StupidBrowser_t pango::pango SDL2::SDL2main cairo::cairo)
else()
	target_link_libraries(StupidBrowser_t litehtml ${PANGO_LIBRARIES} ${CAIRO_LIBRARIES} ${PANGOCAIRO_LIBRARIES} ${SDL2_LIBRARIES})
endif()