#!/bin/sh
base_folder=`pwd`

mkdir build_cmake || true
mkdir output || true
#cd build_cmake && rm * && rm -rf ./bin || cd ..

export SDK_BASE="/opt/fslc-x11-eaton/4.0/sysroots"
export CONAN_FOLDER=`realpath ./build_cmake/`
LOCAL_CMAKE=`which cmake` # the Cmake inside the sdk is old

echo '**' > ./build_cmake/.gitignore
echo '**' > ./output/.gitignore


cd build_cmake 

echo "$CC will be used as compiler"
$CC --version

printf "\nBuilding with CMake\n"
$LOCAL_CMAKE .. -DCMAKE_BUILD_TYPE=Release
$LOCAL_CMAKE --build .

cp ./bin/* ../output/
cp ./DoomCross ../output/
cd ../output 
gunzip -c ../maps/DOOM1.WAD.gz > DOOM1.WAD


cd $base_folder


mv build_cmake build_cmake_xv303 