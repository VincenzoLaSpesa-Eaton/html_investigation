param (
    [switch]$Clean,

	[ValidateSet("xv102", "xv303", "native")]
	[string]$platform = "xv102",
	[switch]$Dirty = $false 
)

if ($PSVersionTable.Platform -eq 'Unix') {
    Write-Output "Running on Linux"
} else {
	throw "This script is meant to be run from inside the WSL"
}

$SDK_BASE="/opt/fslc-x11-eaton/$platform/4.0"
$IMG_NAME=""

switch ($platform) {
    "xv102" { $IMG_NAME="cortexa7t2hf-neon-fslc-linux-gnueabi" }
    "xv303" { $IMG_NAME="cortexa9t2hf-neon-fslc-linux-gnueabi" }
}

$SDK_FULL_PATH="$SDK_BASE/environment-setup-$IMG_NAME"

$build_folder=Join-Path $PWD build_cmake_$platform
$base_folder=$PWD
$output_folder="$base_folder/output_$platform"
$LOCAL_CMAKE=which cmake

$env:VCPKG_ROOT= "/home/vincenzo/vcpkg"


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

# setup the environment

if ($platform -eq 'native') {
    Write-Output "Building with the default toolchain"
	vcpkg update
	if (-Not (Test-Path -Path "$env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake")) {
		throw "No vcpkg toolchain in $env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
	}	
	#vcpkg upgrade
} else {
	if (-Not (Test-Path -Path $SDK_FULL_PATH)) {
		throw "No sdk in $SDK_FULL_PATH"
	}
	Write-Output "Building with the toolchain in $SDK_FULL_PATH"
}


# first build litehtml

if ($dirty -or (Get-ChildItem -Path $build_folder/litehtml).Count -eq 0) {
	Set-Location $base_folder/litehtml
    Write-Output "Build litehtml in $build_folder/litehtml" 
	New-Item -ItemType Directory -Force -Path $output_folder/litehtml

	if ($platform -eq 'native') 
	{
		Push-Location
		Set-Location $build_folder/litehtml
		Copy-Item $base_folder/externals/vcpkg_linux.json vcpkg.json
		Write-Host "Running 'vcpkg install' $PWD"
		vcpkg install
		Pop-Location
		cmake -B $build_folder/litehtml -S . -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" -DBUILD_PLATFORM="$platform"
		cmake --build $build_folder/litehtml
		cmake --install $build_folder/litehtml --prefix $output_folder/litehtml
		Write-Output "Done"
		
	}else
	{
		$script = @"
		source $SDK_FULL_PATH
		export CMAKE_PREFIX_PATH=$SDK_BASE/sysroots/$IMG_NAME/usr:`$CMAKE_PREFIX_PATH
		export CMAKE_INCLUDE_PATH=$SDK_BASE/sysroots/$IMG_NAME/usr/include:`$CMAKE_INCLUDE_PATH
		$LOCAL_CMAKE -B $build_folder/litehtml -S . -DCMAKE_BUILD_TYPE=Release
		$LOCAL_CMAKE --build $build_folder/litehtml
		$LOCAL_CMAKE --install $build_folder/litehtml --prefix $output_folder/litehtml
"@
		
			bash -c "$script"
			Write-Output "Done"		
	}
} else {
    Write-Output "using the litehtml build in $build_folder/litehtml. If you want to force a rebuild delete that folder"
}

# now build the main test program

Set-Location $build_folder

Write-Output "Build the test app in $PWD"

if ($platform -eq 'native') 
{
	Copy-Item $base_folder/externals/vcpkg_linux.json $build_folder/vcpkg.json -Force	
	if(!(Test-Path "skip_vcpkg"))
	{
		Write-Host "Trying to recycle the vcpkg_installed from $build_folder/litehtml/" ; rsync -au $build_folder/litehtml/vcpkg_installed .
	
		Write-Host "Running 'vcpkg install' $PWD"
		New-Item "skip_vcpkg" -ItemType File -Value 'True'
	}
	
	$ErrorActionPreference = "Stop"
	vcpkg install
	Pause


	$env:CMAKE_PREFIX_PATH += [System.IO.Path]::PathSeparator + "$output_folder/litehtml/"
	$env:CMAKE_INCLUDE_PATH += [System.IO.Path]::PathSeparator + "$output_folder/litehtml/include"
	
	# this is weird, vcpkg should inject this stuff by itself! 
	$env:CMAKE_PREFIX_PATH += [System.IO.Path]::PathSeparator + "$build_folder/vcpkg_installed/x64-linux/"
	$env:CMAKE_INCLUDE_PATH += [System.IO.Path]::PathSeparator + "$build_folder/vcpkg_installed/x64-linux/include"
	Write-Host "Search path for the libs should be $env:CMAKE_PREFIX_PATH"
	
	Set-Location $base_folder
	
	
	Write-Host "Calling chame with the toolchain: $env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
	cmake -B $build_folder -S . -DCMAKE_BUILD_TYPE=Release -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
	Set-Location $build_folder
	cmake --build .
	cmake --install . --prefix $output_folder
	
	Write-Output "Done"
	
}else
{
	$script = @"
	source $SDK_FULL_PATH
	export CMAKE_PREFIX_PATH=$SDK_BASE/sysroots/$IMG_NAME/usr:`$CMAKE_PREFIX_PATH
	export CMAKE_INCLUDE_PATH=$SDK_BASE/sysroots/$IMG_NAME/usr/include:`$CMAKE_INCLUDE_PATH
	export CMAKE_PREFIX_PATH=$output_folder/litehtml:`$CMAKE_PREFIX_PATH
	export CMAKE_INCLUDE_PATH=$output_folder/litehtml/include:`$CMAKE_INCLUDE_PATH
	export CMAKE_PREFIX_PATH=$base_folder/externals/sdl/${platform}:`$CMAKE_PREFIX_PATH
	export CMAKE_INCLUDE_PATH=$base_folder/externals/sdl/${platform}/include:`$CMAKE_INCLUDE_PATH
	
	
	$LOCAL_CMAKE .. -DCMAKE_BUILD_TYPE=Release
	$LOCAL_CMAKE --build .
"@

	Add-Content -Path "${platform}_log.log" -Value $script

	
	bash -c "$script"
	Write-Output "Done"
	
}

Copy-Item -Recurse -Force $build_folder/bin $output_folder

Set-Location $base_folder