Project (TurningSquareSDL2)
CMake_Minimum_Required (VERSION 3.0)
Set (CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/cmake/Modules/")

if("${CMAKE_SYSTEM_NAME}" STREQUAL "Windows")
	Set (WIN32_LIBRARIES shlwapi ws2_32 winmm)
else()
	Set (WIN32_LIBRARIES )
endif()

Find_Package (SDL2 REQUIRED)
Find_Package (SDL2_Image REQUIRED)
Find_Package (SDL2_ttf REQUIRED)
# Find_Package (SDL2_Mixer REQUIRED)

Include_Directories(
	${CMAKE_SOURCE_DIR}
	${SDL2_INCLUDE_DIR}
	${SDL2_IMAGE_INCLUDE_DIRS}
	${SDL2_TTF_INCLUDE_DIRS}
)

File (GLOB SOURCES ${PROJECT_SOURCE_DIR}/*.cpp)
File (GLOB HEADERS ${PROJECT_SOURCE_DIR}/*.h)

Add_Executable (TurningSquareSDL2 ${SOURCES} ${HEADERS})

Target_Link_Libraries (
	TurningSquareSDL2
	${SDL2_LIBRARY}
	${SDL2_IMAGE_LIBRARIES}
	${SDL2_TTF_LIBRARIES}
)


