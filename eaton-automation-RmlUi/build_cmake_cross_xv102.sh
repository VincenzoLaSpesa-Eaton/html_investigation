#!/bin/sh
base_folder=`pwd`

mkdir build_cmake || true
mkdir output || true
cd build_cmake ; mkdir  build_RmlUi ; cd ..
#cd build_cmake && rm * && rm -rf ./bin || cd ..

SDK_BASE="/opt/fslc-x11-eaton/xv102/4.0"
IMG_NAME="cortexa7t2hf-neon-fslc-linux-gnueabi"
SDK_FULL_PATH=$SDK_BASE/environment-setup-$IMG_NAME
CONAN_FOLDER=`realpath ./build_cmake/`
LOCAL_CMAKE=`which cmake` # the Cmake inside the sdk is old
BACKEND="SDL_SDLrenderer" #backend is one of auto;native;Win32_GL2;Win32_VK;X11_GL2;SDL_GL2;SDL_GL3;SDL_VK;SDL_SDLrenderer;SFML_GL2;GLFW_GL2;GLFW_GL3;GLFW_VK;BackwardCompatible_GLFW_GL2;BackwardCompatible_GLFW_GL3

echo '**' > ./build_cmake/.gitignore
echo '**' > ./output/.gitignore

if [[ ! -f $SDK_FULL_PATH ]] ; then
    echo "There is no sdk in he path ${SDK_FULL_PATH}"
    exit
fi

source $SDK_FULL_PATH

export CMAKE_LIBRARY_PATH =$base_folder/externals/sdl/xv102:$CMAKE_LIBRARY_PATH 
#export CMAKE_INCLUDE_PATH=$base_folder/externals/sdl/xv102/include:$CMAKE_LIBRARY_PATH

export CMAKE_PREFIX_PATH=$SDK_BASE/sysroots/$IMG_NAME/usr:$CMAKE_PREFIX_PATH
export CMAKE_INCLUDE_PATH=$SDK_BASE/sysroots/$IMG_NAME/usr/include:$CMAKE_LIBRARY_PATH


echo "$CC will be used as compiler"
$CC --version

printf "\nBuild RmlUi\n"

cd RmlUi
# don't create any file inside a submodule folder
$LOCAL_CMAKE -B $base_folder/build_cmake/build_RmlUi -S . --preset samples -DRMLUI_BACKEND=$BACKEND -DCMAKE_BUILD_TYPE=Release
$LOCAL_CMAKE --build $base_folder/build_cmake/build_RmlUi
cd $base_folder

cd build_cmake 
printf "\nBuilding the project\n"
#$LOCAL_CMAKE .. -DCMAKE_BUILD_TYPE=Release
#$LOCAL_CMAKE --build .


cd $base_folder


mv build_cmake build_cmake_xv102_$BACKEND
