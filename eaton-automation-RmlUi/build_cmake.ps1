param (
    [switch]$Clean
)

$vcpkg_folders= @("D:\vcpkg", "D:\Codice\vcpkg")


$env:VCPKG_ROOT= $vcpkg_folders | Where-Object { Test-Path $_ } | Select-Object -First 1
$env:CMAKE_ROOT="C:\Program Files\CMake\bin"
$env:PATH = "$env:VCPKG_ROOT;$env:PATH;$env:CMAKE_ROOT"
$vcpkg="$env:VCPKG_ROOT\vcpkg.exe"
$build_folder=Join-Path $PWD build_cmake_win
$base_folder=$PWD

$BACKEND="Win32_GL2" #backend is one of auto;native;Win32_GL2;Win32_VK;X11_GL2;SDL_GL2;SDL_GL3;SDL_VK;SDL_SDLrenderer;SFML_GL2;GLFW_GL2;GLFW_GL3;GLFW_VK;BackwardCompatible_GLFW_GL2;BackwardCompatible_GLFW_GL3

#git submodule update --init
if ($Clean -And (Test-Path $build_folder)) {
	Write-Host "Cleaning build folder $build_folder"
	Remove-Item $build_folder -r -force
}

if(!(Test-Path $vcpkg)){
	Write-Host "Could not find VCPKG in $vcpkg"
}else{
	Write-Host "VCPKG found in $vcpkg"
}

New-Item -ItemType Directory -Force -Path $build_folder
New-Item -ItemType Directory -Force -Path $build_folder/build_RmlUi
if(!(Test-Path "$build_folder\.gitignore")){
	New-Item "$build_folder\.gitignore" -ItemType File -Value '**'
}

if(!(Test-Path 'output')){
    mkdir output
    New-Item ".\output\.gitignore" -ItemType File -Value '**'
}

Push-Location

Set-Location $build_folder/build_RmlUi
Copy-Item $base_folder/externals/vcpkg_win.json vcpkg.json
vcpkg install

cmake $base_folder/RmlUi --preset samples -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" -DBUILD_PLATFORM="win" -DRMLUI_BACKEND="$BACKEND"
Write-Host "Building!"
cmake --build . --config Release

Pop-Location

#move $build_folder ./build_cmake_win64