param (
    [switch]$Clean,
	[switch]$Dirty = $false 	
)


if ($PSVersionTable.PSEdition -eq 'Core') {
	if ($PSVersionTable.Platform -eq 'Unix') {
		throw "This script is meant to be run from Windows"
	}
}

# it's not the core version, we must be on windows
Write-Output "Running on windows"

##
$platform='x64-windows'

$env:CMAKE_ROOT="C:\Program Files\CMake\bin"
$build_folder=Join-Path $PWD build_cmake_conan_$platform
$base_folder=$PWD
$output_folder="$base_folder/output_$platform"

if ($Clean -And (Test-Path $build_folder)) {
	Write-Host "Cleaning build folder $build_folder"
	Remove-Item $build_folder -r -force
}

New-Item -ItemType Directory -Force -Path $build_folder

New-Item -ItemType Directory -Force -Path $build_folder/litehtml
if(!(Test-Path "$build_folder\.gitignore")){
	New-Item "$build_folder\.gitignore" -ItemType File -Value '**'
}

New-Item -ItemType Directory -Force -Path $output_folder
if(!(Test-Path "$output_folder\.gitignore")){
	New-Item "$output_folder\.gitignore" -ItemType File -Value '**'
}

conan profile detect
# first build litehtml

if ($dirty -or (Get-ChildItem -Path $build_folder/litehtml).Count -eq 0) {
	Set-Location $base_folder/litehtml
    Write-Output "Build litehtml in $build_folder/litehtml"
	New-Item -ItemType Directory -Force -Path $output_folder/litehtml

    conan install $base_folder --output-folder=$build_folder/litehtml --build=missing

    cmake -B $build_folder/litehtml -S . -DCMAKE_BUILD_TYPE=Release # -DCMAKE_TOOLCHAIN_FILE="$build_folder/litehtml/build/generators/conan_toolchain.cmake" -DCMAKE_POLICY_DEFAULT_CMP0091=NEW
	cmake --build $build_folder/litehtml
	#cmake --install $build_folder/litehtml --prefix $output_folder/litehtml #the install does not work ...
	Write-Output "Done"
} else {
    Write-Output "using the litehtml build in $build_folder/litehtml. If you want to force a rebuild delete that folder"
}

# now build the main test program

Write-Output "Build the test app in $PWD"

conan install $base_folder --output-folder=$build_folder --build=missing

Write-Output "---------------"

Set-Location $base_folder
cmake -B $build_folder -S . -DCMAKE_BUILD_TYPE=Release  -DCMAKE_TOOLCHAIN_FILE="$build_folder/build/generators/conan_toolchain.cmake" -DCMAKE_POLICY_DEFAULT_CMP0091=NEW
cmake --build $build_folder
cmake --install $build_folder --prefix $output_folder

Write-Output "Done"
Copy-Item -Recurse -Force $build_folder/bin $output_folder

Set-Location $base_folder
