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
$platform='win'
$vcpkg_folders= @("D:\vcpkg", "D:\Codice\vcpkg")

$base_folder=$PWD
$env:VCPKG_ROOT= $vcpkg_folders | Where-Object { Test-Path $_ } | Select-Object -First 1
$env:CMAKE_ROOT="C:\Program Files\CMake\bin"
$env:PATH = "$env:VCPKG_ROOT;$env:PATH;$env:CMAKE_ROOT"

$env:VCPKG_PYTHON3 = "$base_folder/builder_venv/Scripts/python.exe"
$vcpkg="$env:VCPKG_ROOT\vcpkg.exe"
$build_folder=Join-Path $PWD build_cmake_$platform
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

if(!(Test-Path $vcpkg)){
	Write-Host "Could not find VCPKG in $vcpkg"
}else{
	Write-Host "VCPKG found in $vcpkg"
}

# first build litehtml

if ($dirty -or (Get-ChildItem -Path $build_folder/litehtml).Count -eq 0) {
	Set-Location $base_folder/litehtml
    Write-Output "Build litehtml in $build_folder/litehtml"
	New-Item -ItemType Directory -Force -Path $output_folder/litehtml


	Push-Location
	Set-Location $build_folder/litehtml
	Copy-Item $base_folder/externals/vcpkg_win.json vcpkg.json
	Write-Host "Running 'vcpkg install' $PWD"
	Invoke-Expression "$vcpkg install"

	Pop-Location
	
	cmake -B $build_folder/litehtml -S . -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
	cmake --build $build_folder/litehtml
	cmake --install $build_folder/litehtml --prefix $output_folder/litehtml
	Write-Output "Done"
} else {
    Write-Output "using the litehtml build in $build_folder/litehtml. If you want to force a rebuild delete that folder"
}
Pause

# now build the main test program

Write-Output "Build the test app in $PWD"
Set-Location $build_folder
Copy-Item $base_folder/externals/vcpkg_win.json $build_folder/vcpkg.json
Write-Host "Trying to recycle the vcpkg_installed from $build_folder/litehtml/"
Copy-Item -Recurse -Force $build_folder/litehtml/vcpkg_installed .
Write-Host "Running 'vcpkg install' $PWD"
Invoke-Expression "$vcpkg install"

$env:CMAKE_PREFIX_PATH="$output_folder/litehtml";$env:CMAKE_PREFIX_PATH
$env:CMAKE_INCLUDE_PATH="$output_folder/litehtml/include";$env:CMAKE_PREFIX_PATH

Set-Location $base_folder

cmake -B $build_folder -S . -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
cmake --build $build_folder
cmake --install $build_folder --prefix $output_folder

Write-Output "Done"
Copy-Item -Recurse -Force $build_folder/bin $output_folder
