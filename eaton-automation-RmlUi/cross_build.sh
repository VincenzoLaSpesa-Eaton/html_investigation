rm -rf output
rm -rf build_cmake
base=`pwd`

bash build_cmake.sh && mv output output_linux_x64 && rm -rf build_cmake

cd $base
dockcross-manylinux2014-x86 bash build_cmake.sh && mv output output_linux_x86 && rm -rf build_cmake

cd $base
dockcross-linux-armv7-lts bash build_cmake.sh && mv output output_xv303_d && rm -rf build_cmake

cd $base
bash build_cmake_cross_xv303.sh
