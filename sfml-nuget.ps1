#
# sfml-nuget.ps1
# v2_2.5.1
#

#########################

# Some customisation variables
$pkg_prefix = "" # Prefix of packages.
$pkg_postfix = "" # Postfix of packages.
$keep_sources = $true # Use $true to keep source files or $false to delete them, $true by default
$keep_autopkg = $false # Keep autopkg files, $false by default
$add_docs = $false # Add docs in system module, $false by default
$pkg_hotfix = "" # Packages hotfix version, "" by default [means no hotfix]

# SFML packages variables
$sfml_owners =	"username" # Packages "owner" name. Replace username with your name
$sfml_tags = "sfml, C++, graphics, multimedia, games, opengl, audio, native, CoApp" # Tags for your packages, "sfml, C++, graphics, multimedia, games, opengl, audio, native, CoApp" by default

# SFML nuget packages 'generation' variables
$sfml_module_list = "system", "window", "graphics", "audio", "network" # SFML packages, that will be generated
$sfml_version = "2.5.1" # SFML version, min supported version - 2.2
$sfml_platforms = "x86", "x64"
$sfml_toolchains = "v120", "v140", "v141"
$sfml_configurations = "debug", "release"

#########################

# It's not recommended to change these values
$sfml_download_url = "http://www.sfml-dev.org/files/"
$sfml_authors = "Laurent Gomila"
$sfml_licence_url = "http://www.sfml-dev.org/license.php"
$sfml_project_url = "http://www.sfml-dev.org"
$sfml_icon_url = "http://www.sfml-dev.org/images/sfml-icon.png"
$sfml_require_license_acceptance = "false"
$sfml_summary = "SFML provides a simple interface to the various components of your PC, to ease the development of games and multimedia applications. It is composed of five modules: system, window, graphics, audio and network."
$sfml_description = "SFML provides a simple interface to the various components of your PC, to ease the development of games and multimedia applications. It is composed of five modules: system, window, graphics, audio and network.
With SFML, your application can compile and run out of the box on the most common operating systems: Windows, Linux, Mac OS X and soon Android & iOS.
SFML has official bindings for the C and .Net languages. And thanks to its active community, it is also available in many other languages such as Java, Ruby, Python, Go, and more."
$sfml_changelog = "https://www.sfml-dev.org/changelog.php#sfml-$sfml_version"

# Don't change these values
$dir = Split-Path $MyInvocation.MyCommand.Path
$coapp_download_url = "http://coapp.org/pages/releases.html"
$linking = "static", "dynamic"
$to_msvc = @{ "v100" = "vc10"; "v110" = "vc11"; "v120" = "vc12"; "v140" = "vc14"; "v141" = "vc15" }
$to_bits = @{ "x86" = "32"; "Win32" = "32" ; "x64" = "64" }
$dependencies = @{ "window" = "system"; "graphics" = ("window", "system"); "audio" = "system"; "network" = "system" }
$sfml = "sfml."

#########################

function PackageHeader($pkgName)
{
	$currentYear = (Get-Date).Year
	return "configurations {
	UserPlatformToolset {
	// Needed because autopackage lacks VS2015 support
		key = ""PlatformToolset"";
		choices: ""v120, v140, v141"";
	};
}

nuget {
	nuspec {
		id = $pkg_prefix$sfml$pkgName$pkg_postfix;
		title: $pkg_prefix$sfml$pkgName$pkg_postfix;
		version: $sfml_version$pkg_hotfix;
		authors: { $sfml_authors };
		owners: { $sfml_owners };
		licenseUrl: ""$sfml_licence_url"";
		projectUrl: ""$sfml_project_url"";
		iconUrl: ""$sfml_icon_url"";
		requireLicenseAcceptance: $sfml_require_license_acceptance;
		summary: ""$sfml_summary"";
		description: @""$sfml_description"";
		releaseNotes: ""$sfml_changelog"";
		copyright: Copyright $currentYear;
		tags: ""$sfml_tags"";
	}

	#output-packages {
		default : `${pkgname};
		redist : `${pkgname}.redist;
		symbols : `${pkgname}.symbols;
	}"
}

function AddMainFile()
{
	$datas = ""
	foreach($p in $sfml_platforms)
	{
		foreach($v in $sfml_toolchains)
		{
			foreach($c in $sfml_configurations)
			{
				$datas += "		[$p,$v,$c] {"
				$libfile = "			lib: { `${SRC}lib\$p\$v\$c\sfml-main"
				if ($c -eq "debug")
				{
					$libfile += "-d"
				}
				$libfile += ".lib };"
				$datas += "
$libfile
		}

"
			}
		}
	}
	return $datas
}

function AddFiles($pkgName)
{
	$datas = ""
	foreach($p in $sfml_platforms)
	{
		foreach($v in $sfml_toolchains)
		{
			foreach($c in $sfml_configurations)
			{
				foreach($l in $linking)
				{
					$datas += "		[$p,$v,$c,$l] {"
					$libfile = "			lib: { `${SRC}lib\$p\$v\$c\sfml-$pkgName"
					$binfile = "			bin: { `${SRC}bin\$p\$v\$c\sfml-$pkgName"
					if ($l -eq "static")
					{
						$libfile += "-s"
					}
					if ($c -eq "debug")
					{
						$libfile += "-d"
						$binfile += "-d"
					}
					$libfile += ".lib };"
					$binfile += "-2.dll };"
					$datas += "
$libfile"

					if ($l -eq "dynamic")
					{
						$datas += "
$binfile"
					}
					$datas += "
		}

"
				}
			}
		}
	}
	return $datas
}

function AddDependencies($pkgName)
{
	if (-not $dependencies.ContainsKey($pkgName))
	{
		return ""
	}
	$datas += "

	dependencies {
		packages : {"
	foreach($package in $dependencies[$pkgName])
	{
		$datas += "
			$pkg_prefix$sfml$package$pkg_postfix/$sfml_version$pkg_hotfix,"
	}
	$datas = $datas.TrimEnd(",")
	$datas += "
		};
	}"
	return $datas
}

function GeneratePackage($pkgName)
{

	$autopkg = PackageHeader($pkgName)
	$autopkg += AddDependencies($pkgName)
	$autopkg += "

	files {
		#defines {
			SRC = ..\sources\;
		}

"
	if ($pkgName -eq "system")
	{
		$autopkg += "		nestedInclude: {
			#destination = `${d_include}$include_workaround;
			""`${SRC}include\**\*""
		};

"
		$autopkg += "		docs: {
			`${SRC}docs\**\*
		};

"
		$autopkg += AddMainFile
	}
	$autopkg += AddFiles($pkgName)
	if ($pkgName -eq "system")
	{
		foreach ($p in $sfml_platforms)
		{
			foreach ($v in $sfml_toolchains)
			{
				$autopkg += "		[$p,$v] {
			lib: { `${SRC}ext\lib\$p\$v\*.lib };
			bin: { `${SRC}ext\bin\$p\$v\*.dll };
		}

"
			}
		}
	}
	$autopkg = $autopkg.TrimEnd("`r`n")
	$autopkg += "
	};

	targets {
		Defines += HAS_SFML;

		[static]
		Defines += SFML_STATIC;
	}
}"
	$autopkg | Out-File "$pkg_prefix$sfml$pkgName$pkg_postfix.autopkg"
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
	param([string]$zipfile, [string]$outpath)
	[System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

function CreateDirectory($dirName)
{
	if (-not (Test-Path $dirName)){
		New-Item "$dirName" -ItemType Directory -Force | Out-Null
	}
}

function CreateFile($fileName)
{
	if (-not (Test-Path $fileName)){
		New-Item "$fileName" -ItemType File -Force | Out-Null
	}
}

#########################
########## Main #########
#########################

# Checking on installed CoApp Tools
try
{
	Show-CoAppToolsVersion | Out-Null
}
catch
{
	Write-Host -ForegroundColor Yellow "You need CoApp tools to build NuGet packages!"
	Read-Host "Press ENTER to open CoApp website or Ctrl-C to exit..."
	Start-Process $coapp_download_url
	Exit
}

if ($pkg_hotfix -ne "")
{
	$pkg_hotfix = $pkg_hotfix.Insert(0, ".")
	if (($sfml_version) -notmatch "^(\d+)\.(\d+)\.(\d+)$")
	{
		$pkg_hotfix = $pkg_hotfix.Insert(0, ".0")
	}
}

CreateDirectory("$dir\temp")
CreateDirectory("$dir\sources")
CreateDirectory("$dir\sources\include")
CreateDirectory("$dir\distfiles")
CreateDirectory("$dir\build")
CreateDirectory("$dir\sources\docs")

foreach($p in $sfml_platforms)
{
	foreach ($v in $sfml_toolchains)
	{
		$filename = "SFML-$sfml_version-windows-" + $to_msvc[$v] + "-" + $to_bits[$p] + "-bit.zip"
		$outfile = "$dir\distfiles\$filename"
		if (-not (Test-Path $outfile))
		{
			$fileuri = $sfml_download_url + $filename
			$webclient = New-Object System.Net.WebClient
			$downloaded = $false
			while ($downloaded -eq $false)
			{
				try
				{
					Write-Host "`nDownloading $filename..."
					$webclient.DownloadFile($fileuri, $outfile)
					$downloaded = $true
					Write-Host -ForegroundColor Green "$filename downloaded"
				}
				catch
				{
					Write-Warning "An error occurred while downloading the file $fileuri"
					Write-Host -ForegroundColor Yellow "Press ENTER to try again or Ctrl-C to exit..."
					Read-Host
				}
			}
		}
		Write-Host "`nExtracting $filename..."
		Remove-Item "$dir\temp\" -Recurse | Out-Null # Clearing directory to avoid Unzip exceptions
		Unzip "$outfile" "$dir\temp"
		$zip = "$dir\temp\SFML-$sfml_version"

		CreateDirectory("$dir\sources\ext\lib\$p\$v\")
		CreateDirectory("$dir\sources\ext\bin\$p\$v\")
		CreateDirectory("$dir\sources\bin\$p\$v\debug\")
		CreateDirectory("$dir\sources\bin\$p\$v\release\")
		CreateDirectory("$dir\sources\lib\$p\$v\debug\")
		CreateDirectory("$dir\sources\lib\$p\$v\release\")
		CreateDirectory("$dir\sources\docs\")

		Copy-Item "$zip\include\*" "$dir\sources\include\" -Force -Recurse | Out-Null
		if ($add_docs -ne $false)
		{
			Copy-Item "$zip\doc\*" "$dir\sources\docs\" -Force -Recurse | Out-Null
		}
		Get-Item "$zip\*" -Include "*.txt","*.md" | Move-Item -Destination "$dir\sources\docs\" -Force | Out-Null
		Move-Item "$zip\bin\sfml-*-d-2.dll" "$dir\sources\bin\$p\$v\debug\" -Force | Out-Null
		Move-Item "$zip\bin\sfml-*.dll" "$dir\sources\bin\$p\$v\release\" -Force | Out-Null
		Move-Item "$zip\bin\*.dll" "$dir\sources\ext\bin\$p\$v\" -Force | Out-Null
		Move-Item "$zip\lib\sfml-*-d.lib" "$dir\sources\lib\$p\$v\debug" -Force | Out-Null
		Move-Item "$zip\lib\sfml-*.lib" "$dir\sources\lib\$p\$v\release" -Force | Out-Null
		Move-Item "$zip\lib\*.lib" "$dir\sources\ext\lib\$p\$v\" -Force | Out-Null
		Remove-Item "$zip" -Recurse | Out-Null
	}
}

if ((Get-ChildItem "$dir\sources\include\" -File -Force).Count -gt 0)
{
	$include_workaround = ""
}
else
{
	$include_workaround = "SFML\"
}

Write-Host
Set-Location "$dir\build"
foreach($module in $sfml_module_list)
{
	Write-Host "Generating $pkg_prefix$sfml$module$pkg_postfix.autopkg..."
	GeneratePackage($module)
}
Set-Location ..

New-Item "$dir\repository" -ItemType Directory -Force | Out-Null
Set-Location "$dir\repository"
Get-ChildItem "../build/" -Filter *.autopkg | `
Foreach-Object{
	Write-Host "`nGenerating NuGet package from $_...`n"
	Write-NuGetPackage ..\build\$_ | Out-Null
	if ($keep_autopkg -eq $false) {
		Remove-Item ..\build\$_ | Out-Null
	}
}
Write-Host "`nCleaning..."
Remove-Item *.symbols.* | Out-Null
Set-Location ..
Remove-Item "$dir\temp" -Recurse | Out-Null
if ($keep_autopkg -eq $false)
{
	Remove-Item "$dir\build" -Recurse | Out-Null
}
if ($keep_sources -ne $true)
{
	Remove-Item "$dir\sources" -Recurse | Out-Null
}
Write-Host -ForegroundColor Green "Done! Your packages are available in $dir\repository"
Pause