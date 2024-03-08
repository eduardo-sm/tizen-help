#!/usr/bin/env powershell

<#
.SYNOPSIS
  Helper script for tizen and sdb command line tools.

.DESCRIPTION
  The tizen-help is a script that wraps around tizen command (batch script on windows and shell script on mac/linux) and sdb (smart debug bridge).
  It aims to provide a simpler API for development with Samsung TVs. It also provides nice utility functions like a syntax helper, the avility to repackage a wgt with the current profile, or change signing profile.

.PARAMETER SubCommand
  Name of the function to call. Sub commands available:
    - install       > Install the app provided [wgt-path] in the target tv.
                      Optional device-ip to target action.
    - uninstall     > Uninstall the app in the tv. It accepts both [app-id] or [wgt-path].
                      Optional device-ip to target action.
    - debug         > Start a debug session of the app that matches the [app-id] or [wgt-path]
                      If CHROMIUM variable exitst, it will launch it the browser
                      If DISABLE_WEB_SECURITY is "true", it will use disable-web-security flag.
                      Optional device-ip to target action.
    - build         > Builds a tizen project in the specified directory
                      and outs the results in .buildResult located in the specified directory.
    - package       > Package a tizen app (wgt) in the directory specified.
    - connect       > Connect to the TV using the provided IP or the IP in SAMSUNG_DEVICE_IP variable.
    - disconnect    > Disconnect from the TV using the provided IP or the IP in SAMSUNG_DEVICE_IP variable.
    - appid         > Show the [app-id] from a given [wgt] file.
    - repackage     > Unpack and repack a wgt using the active signing profile.
    - profile       > Sets a profile for signing. If no profile is provided, a menu will open to choose
                      from current profiles. If fzf is available, it will be use to display the menu.
    - info          > Show current value of CHROMIUM and SAMSUNG_DEVICE_IP variables
                      as well as the result of "tizen version" and "sdb version".
    - syntax        > Show syntax help of common uses cases of tizen cli.
    - help          > Prints this message.
    - version       > Show script version.

.PARAMETER FilePath
  Second argument for most functions is the path to directory or a file but this could also be an id. Please check SubCommand for more information.

.PARAMETER ExtraArg
  Extra argument for some SubCommands. E.g. Calling connect or install will allow you to provide a third argument to target a specific device. Please check SubCommand for more information.

.INPUTS
  The script does not take inputs from a pipeline.

.OUTPUTS
  The script returns minimal output that can be piped, although it is not recomended. The script will mostly work with files in the filesystem.

.EXAMPLE
  tizen-help build ./build

.EXAMPLE
  tizen-help package ./build/.buildResult

.EXAMPLE
  tizen-help install ./build/.buildResult/MY_APP.wgt

.EXAMPLE
  tizen-help install ./build/.buildResult/MY_APP.wgt 192.168.1.100

.EXAMPLE
  tizen-help debug ./build/.buildResult/MY_APP.wgt

.EXAMPLE
  tizen-help debug ./build/.buildResult/MY_APP.wgt 192.168.23.17

.EXAMPLE
  tizen-help uninstall ./build/.buildResult/MY_APP.wgt

.EXAMPLE
  tizen-help uninstall ./build/.buildResult/MY_APP.wgt 192.168.2.2

.EXAMPLE
  tizen-help -SubCommand install -PathName ./build/.buildResult/MY_APP.wgt -ExtraArg 172.23.21.8

.EXAMPLE
  tizen-help -PathName ./build/.buildResult/MY_APP.wgt -SubCommand debug

.NOTES
  The script can customized with the following environment variables:
  - SAMSUNG_DEVICE_IP: If provided, it will be the ip used by default when a subcommand requires the ip to the target device.
  - CHROMIUM: Path to the browser to open the debugger. It is used only for the subcommand 'debug'. If not provided, a debug session will still be created but you will need to manually open the debug server in your chromium based browser manually. 
  - DISABLE_WEB_SECURITY: If set to 'true', the debug session will be created using the disable web security flags. This may be useful for development.
  - DEBUG: If set to 'true', the script will run with "Set-PSDebug -Trace 1" which will allow to thoubleshoot issues.

  Additionally, you need to make sure that both tizen and sdb commands are installed and available in your path.

  You can check this by running `tizen-help info`. The script will output the available information.

#>

Param (
  # Function to call from the script
  [String] $SubCommand = '',
  # Argument needed for some subcommands like a path to a file or directory or an id.
  [String] $FilePath = '',
  # Additional argument to customize the functionality of some subcommands
  [String] $ExtraArg = ''
)

$args_array = @(
  $SubCommand,
  $FilePath,
  $ExtraArg
)

function : () {}

# Enable environment variable 'debug' to
# set debug trace
if ($env:debug) {
  Set-PSDebug -Trace 1

  function : () {
    Write-Output "$args"
  }
}

# Common chrome/chromium location:
# mac
# TODO: Investigate default locations for Powershell on mac
#
# windows
#   '$env:LocalAppData/Chromium/Application/chrome.exe'
#   'C:/Program Files/Google/Chrome/Application/chrome.exe'
# linux
#
# TODO: Investigate default locations for Powershell on linux
#
# Disable security flags if needed (all flags are required!)
#   --disable-web-security
#   --user-data-dir=/tmp/tmp-dev-dir
#   --disable-site-isolation-trials

: :: 'Variable declaration'
$version="1.2.4"

# Using windows default
$chromium = if ($env:CHROMIUM) { $env:CHROMIUM } else { "$env:LocalAppData/Chromium/Application/chrome.exe" }
$device_ip = if ($env:SAMSUNG_DEVICE_IP) { $env:SAMSUNG_DEVICE_IP } else { '' }
# Open browser web security disabled
$disable_web_security = $env:DISABLE_WEB_SECURITY -eq 'true'

# Device to connect
$device_id = ""
$tmp_dir_name = "tmp-dev-dir"

# Serial is usually ip + default port
$serial_number = "${device_ip}:26101"

$starting_location = (Get-Location).ToString()
# home_location="$HOME"
# $pathid = ""
$tizen_tmp = ""

# Helper functions
function get_temp_debug_dir () {
  "${env:Temp}/$script:tmp_dir_name"
}

function get_temp_dir () {
  $uuid = New-Guid
  "${env:Temp}/tizen-help/$uuid"
}

# handle_wsl_path () {
#   : :: 'Empty function'
# }

function is_command ([String] $command) {
  $oldPreference = $ErrorActionPreference
  $ErrorActionPreference = 'stop'
  try {
    if (Get-Command $command) { return $true }
  } catch { return $false }
  finally { $ErrorActionPreference = $oldPreference }
}

# Detect windows
# Powershell includes built-in variables
# - IsWindows
# - IsLinux
# - IsMacOS

function print_version () {
  Write-Output "tizen-help - v$script:version"
}

function tizen_help () {
  $name = $MyInvocation.MyCommand.Name

  Write-Output @"
  Tizen helper for CLI use - v$script:version

  Commands:
    - install       > Install the app provided [wgt-path] in the target tv.
                      Optional device-ip to target action.
    - uninstall     > Uninstall the app in the tv. It accepts both [app-id] or [wgt-path].
                      Optional device-ip to target action.
    - debug         > Start a debug session of the app that matches the [app-id] or [wgt-path]
                      If CHROMIUM variable exitst, it will launch it the browser
                      If DISABLE_WEB_SECURITY is "true", it will use disable-web-security flag.
                      Optional device-ip to target action.
    - build         > Builds a tizen project in the specified directory
                      and outs the results in .buildResult located in the specified directory.
    - package       > Package a tizen app (wgt) in the directory specified.
    - connect       > Connect to the TV using the provided IP or the IP in SAMSUNG_DEVICE_IP variable.
    - disconnect    > Disconnect from the TV using the provided IP or the IP in SAMSUNG_DEVICE_IP variable.
    - appid         > Show the [app-id] from a given [wgt] file.
    - repackage     > Unpack and repack a wgt using the active signing profile.
    - profile       > Sets a profile for signing. If no profile is provided, a menu will open to choose
                      from current profiles. If fzf is available, it will be use to display the menu.
    - info          > Show current value of CHROMIUM and SAMSUNG_DEVICE_IP variables
                      as well as the result of "tizen version" and "sdb version".
    - syntax        > Show syntax help of common uses cases of tizen cli.
    - help          > Prints this message.
    - version       > Show script version.

	Usage:
    ${name} install [ wgt-path ] [ device-ip ]
    ${name} uninstall [ app-id | wgt-path ] [ device-ip ]
    ${name} debug [ app-id | wgt-path ] [ device-ip ]
    ${name} build [ path-to-build ]
    ${name} package [ path-to-package ]
    ${name} connect [device-ip]
    ${name} disconnect [device-ip]
    ${name} appid [ wgt-path ]
    ${name} repackage [ wgt-path ]
    ${name} profile [ profile-name ]
    ${name} info
    ${name} syntax
    ${name} help
    ${name} version

	Options:
    -h | --help                   Print this message
    -v | --version                Print script version

  Environment variables:
    - CHROMIUM                    Path of the browser executable
    - SAMSUNG_DEVICE_IP           IP Address of the device to connect to
    - DISABLE_WEB_SECURITY        Start the browser with web security disabled [ true | false ]

  Debug errors with the script:
    > Set a debug environment variable to enable 'Set-PSDebug' logs
    > `$env:debug = true && ${name} info

  Examples of use:
    # Build will always create a .buildResult directory
    > ${name} build ./build

    # Package your build in a wgt. Current signing profile will be used.
    > ${name} package ./build/.buildResult

    # Install can accept a second argument to target a device. Overrides SAMSUNG_DEVICE_IP env variable.
    > ${name} install ./build/.buildResult/MY_APP.wgt

    # Debug can accept a second argument to target a device. Overrides SAMSUNG_DEVICE_IP env variable.
    > ${name} debug ./build/.buildResult/MY_APP.wgt

    # Uninstall can accept a second argument to target a device. Overrides SAMSUNG_DEVICE_IP env variable.
    > ${name} uninstall ./build/.buildResult/MY_APP.wgt
"@
}

function syntax_help () {
  Write-Output @"
    Tizen syntax:

    Security profiles:
      Show profiles:
      - tizen security-profiles list
      Set a profile:
      - tizen security-profiles set-active -n [profile-name]

    Build:
      - tizen build-web -out [out directory] [-- directory path]

    Package:
      If specific cert required:
      - tizen security-profiles add -n [profile-name] -a [author.p12 path] -p [password]

      - tizen package -t wgt [-s profile-name] [-- directory path]

    Connect:
      - sdb connect [device-ip]
      - sdb disconnect [device-ip]

    Server:
      - sdb start-server
      - sdb kill-server

    Install: (use wgt location)
      - tizen install -n [wgt-path]
      - tizen uninstall -p [app-id]

    Debug:
      - sdb shell 0 debug [app-id]
      - sdb forward tcp:[port] tcp:[port]

    Restart app (javascript):
      - tizen.application.launch("[app-id]")
"@
}

function open_brwoser ([String] $url) {
  Write-Output "
opening chromium"

  $browser_args = @()

  if ($script:disable_web_security) {
    Write-Output "
Starting --disable-web-security session"
    $temp_dir = get_temp_debug_dir

    New-Item -Type Directory -Force "$temp_dir"

    $browser_args = @(
      '--disable-web-security',
      "--user-data-dir=$temp_dir",
      '--disable-site-isolation-trials',
      '--disable-features=EnableRemovingAllThirdPartyCookies'
    )

    : :: "Browser session is located in the temporal directory $temp_dir"
  }

  : :: "Command: & $script:chromium $browser_args $url"
  # Call browser executable. If disable web security is enabled
  # then browser args will have all the required flags
  & "$script:chromium" @browser_args "$url"
}

function tizen_build ([String] $location) {
  if (-Not (Test-Path -PathType Container -Path "$location" -ErrorAction SilentlyContinue)) {
    die "Invalid path provided: $location"
    return
  }

  tizen build-web -- "$location" -out .buildResult
}

function tizen_package ([String] $location) {
  if (-Not (Test-Path -PathType Container -Path "$location" -ErrorAction SilentlyContinue)) {
    die "Invalid path provided: $location"
    return
  }

  tizen package -t wgt -- "$location"
}

function tizen_repackage ([String] $location) {
  : :: "Repackage file location: $location"
  if (-Not (Test-Path -PathType Leaf -Path "$location" -ErrorAction SilentlyContinue)) {
    die "Input is not a valid file: $location"
    return
  }

  : :: "Prepare temporal location"
  $script:tizen_tmp = if ($script:tizen_tmp) { $script:tizen_tmp } else { get_temp_dir }
  $temp_unzip_dir = "$script:tizen_tmp/repackage"
  # trap "rm -rf -- '$temp_unzip_dir' &> /dev/null" EXIT

  try {
    : :: "Unzip original build"
    Expand-Archive -Path "$location" -DestinationPath "$temp_unzip_dir"

    : :: "Make new signed build"
    Set-Location "$temp_unzip_dir"
    tizen package -t wgt -- .

    $name = [System.IO.Path]::GetFileNameWithoutExtension($location)
    $repacked_file = "$name.repacked.wgt"

    : :: "Go back to starting location"
    Set-Location "$script:starting_location"
    : :: "Copy new file $repacked_file"
    $new_wgt = Get-ChildItem -Path "$temp_unzip_dir" -Recurse -Filter *.wgt | Select-Object -ExpandProperty Name
    Copy-Item "$temp_unzip_dir/$new_wgt" "$repacked_file"
  } finally {
    if (Test-Path -PathType Container -Path "$temp_unzip_dir" -ErrorAction SilentlyContinue) {
      Remove-Item -Recurse -Force "$temp_unzip_dir"
    }
  }
}

function show_current () {
  Write-Output @"
    Environment:
    Chromium: $script:chromium
    Device IP: $script:device_ip
    Disable web security: $script:disable_web_security

    tizen version output:
    $(tizen version)

    sdb version output:
    $(sdb version)
"@
}

function start_connection ([String] $ip) {
  $script:device_ip = if ($ip) { $ip } else { $env:SAMSUNG_DEVICE_IP }

  : :: "Device ip $script:device_ip"
  if (-Not "$script:device_ip") {
    die "Cannot proceed without a valid IP"
    return
  }

  $script:serial_number = "$script:device_ip:26101"

  Write-Output "
Connecting to $script:device_ip ..."
  sdb connect "$script:device_ip"
}

function close_connection ([String] $ip) {
  $script:device_ip = if ($ip) { $ip } else { $env:SAMSUNG_DEVICE_IP }

  if (-Not "$script:device_ip") {
    die "Cannot proceed without a valid IP"
    return
  }

  $script:serial_number = "$script:device_ip:26101"

  if (-Not "$script:device_id") {
    set_device_id
  }

  Write-Output "
Disconnection from device $script:device_id at $script:device_ip..."
  sdb disconnect "$script:device_ip"
}

function start_deamon () {
  Write-Output "
Starting sdb server..."
  sdb start-server
}

function end_deamon () {
  Write-Output "
Stopping sdb server..."
  sdb kill-server
}

function set_device_id () {
  Write-Output "
Setting device id"
  $script:device_id = $(sdb devices | awk -v serial="$script:serial_number" '{ if($1 == serial) { print $3 } }' | tr -d '[:space:]')
  $script:device_id = (sdb devices | Select-String -Pattern "^$script:serial_number").ToString().Split("`t")
  Write-Output "DeviceID: $script:device_id"
}

#display error message and exit
function die () {
  Write-Error "$args"
	Exit 1
}

function get_app_id ([String] $location) {
  $app_id = ''

  if ((Test-Path -PathType Leaf -Path "$location" -ErrorAction SilentlyContinue) -or ("$location" -Like "*.wgt")) {
    $temp_ext_dir = get_temp_dir
    Expand-Archive -Path "$location" -DestinationPath "$temp_ext_dir"

    $app_id = (Get-Content "$temp_ext_dir/config.xml" | Select-String -Pattern "tizen:application.* id=`"([a-zA-Z0-9\.]*)`"").Matches.Groups[1].Value

    Remove-Item -Recurse -Force "$temp_ext_dir"
  } else {
    $app_id = $location
  }

  if (-Not "$app_id") {
    die "Invalid app id provided"
    return
  }

  return "$app_id"
}

function show_app_id ([String] $file_name) {
  if (-Not (Test-Path -PathType Leaf -Path "$file_name" -ErrorAction SilentlyContinue)) {
    die "Invalid file provided"
    return
  }

  $app_id = get_app_id "$file_name"

  if (-Not "$app_id") {
    die "Unable to get app id"
    return
  }

  Write-Output "
The app id of '$file_name' is: $app_id"
}

function tizen_install ([String] $file_name) {
  if (-Not "$script:device_id") {
    set_device_id
  }

  if (Test-Path -PathType Container -Path "$script:tizen_tmp" -ErrorAction SilentlyContinue) {
    Set-Location "$script:tizen_tmp"
    tizen install -n "$([System.IO.Path]::GetFileName($file_name))" -t "$script:device_id"
    Set-Location "$script:starting_location"
  } else {
    tizen install -n "$file_name" -t "$script:device_id"
  }
}

function tizen_uninstall ([String] $file_name) {
  $app_id = get_app_id $file_name

  if (-Not "$script:device_id") {
    set_device_id
  }

  Write-Output "
The uninstall command may not work on old devices"

  tizen uninstall -p "$app_id" -t "$script:device_id"
}

function tizen_debug ([String] $file_name) {
  if (-Not "$script:device_ip") {
    die "Cannot proceed without a valid IP"
    return
  }

  if (-Not "$script:device_id") {
    set_device_id
  }

  $app_id = get_app_id "$file_name"

  Write-Output "
Start debugging for app id $app_id"

  # Launch sdb debug and capture port
  $debug_port = ("$(sdb -s "$script:serial_number" shell 0 debug "$app_id")" -Split ' ')[10].Trim()

  $url = "http://$script:device_ip"
  $url = "${url}:${debug_port}"

  if (-Not "$debug_port") {
    die "Unable to launch the app $app_id in debug mode. Please verify that the app id is valid."
    return
  }

  # Connect tv debug port to pc port
  sdb -s "$script:serial_number" forward tcp:$debug_port tcp:$debug_port

  Write-Host "
Debug port available on $url

You can restart your app in the console with:
> tizen.application.launch('$app_id')
NOTE: The function may not work on old devices."

  if (Test-Path -PathType Leaf -Path "$script:chromium" -ErrorAction SilentlyContinue) {
    open_brwoser "$url"
  }
}

function choose_profile () {
  $profiles = @(tizen security-profiles list | Select-Object -Skip 2 | % {
    $temp = $_.TrimEnd("`t O")
    $temp.Trim()
  })

  for (($i = 0); $i -lt $profiles.Length; $i++) {
    $pro = $profiles[$i]
    Write-Host "${i}: $pro"
  }

  $selection = Read-Host -Prompt "
Enter the number of the profile or 'q' to quit"

  if ($selection -eq 'q') {
    : :: "No profile selected."
    return
  }

  : :: "Selected profile: $selection"

  $profile = $profiles[$selection]

  if (-Not $profile) {
    die "Selected profile '$selection' is invalid."
    return 1
  }

  tizen security-profiles set-active -n "$profile"
}

function choose_profile_fzf () {
  # Usage of a temporal buffer is needed. If piping the result of Select-Object into
  # fzf directly, arrow keys won't refresh automatically
  $temporal_buffer = New-TemporaryFile
  tizen security-profiles list | Select-Object -Skip 2 > $temporal_buffer.FullName
  $profile = Get-Content $temporal_buffer.FullName | fzf | % {
    $temp = $_.TrimEnd("`t O")
    $temp.Trim()
  }

  : :: "Selected profile: $profile"
  if (-Not "$profile") {
    : :: "No profile selected."
    return
  }

  tizen security-profiles set-active -n "$profile"
}

function change_profile ([String] $profile) {
  if ("$profile") {
    : :: "Setting Profile: $1"
    tizen security-profiles set-active -n "$profile"
    return $?
  }

  if (is_command 'fzf') {
    : :: "Using fzf to select profile"
    choose_profile_fzf
    return
  }

  choose_profile
}

function main () {
  : ::: Evaluating args :::
  : :: "$script:args_array"

  switch -Regex ($SubCommand) {
    "^connect$" {
      start_deamon
      start_connection "$FilePath"
      break
    }
    "^disconnect$" {
      $lines_count = sdb devices | Measure-Object | Select-Object -ExpandProperty Count
      if ($lines_count > 2) {
        close_connection "$FilePath"
      } else {
        close_connection "$FilePath"
        end_deamon
      }
      break
    }
    "^install$" {
      $target_ip = $ExtraArg || $null
      if ("$target_ip") {
        start_deamon
        start_connection "$target_ip"
      }

      tizen_install "$FilePath"
      break
    }
    "^uninstall$" {
      $target_ip = $ExtraArg || $null
      if ("$target_ip") {
        start_deamon
        start_connection "$target_ip"
      }

      tizen_uninstall "$FilePath"
      break
    }
    "^debug$" {
      $connection_ip = if ($ExtraArg) { $ExtraArg } else { $script:device_ip }
      start_deamon
      start_connection "$connection_ip"
      tizen_debug "$FilePath"
      break
    }
    "^build$" {
      tizen_build "$FilePath"
      break
    }
    "^package$" {
      tizen_package "$FilePath"
      break
    }
    "^appid$" {
      show_app_id "$FilePath"
      break
    }
    "^info$" {
      show_current
      break
    }
    "^syntax$" {
      syntax_help
      break
    }
    "^profile$" {
      change_profile "$FilePath"
      break
    }
    "^repackage$" {
      tizen_repackage "$FilePath"
      break
    }
    "^(-h|--help|help)$" {
      tizen_help
      break
    }
    "^(-v|--version|version)$" {
      print_version
      break
    }
    default {
      Write-Output "
Invalid command argument '$args_array'"
      tizen_help
      break
    }
  }
}

try {
  main
} finally {
  if (Test-Path -PathType Container -Path "$tizen_tmp" -ErrorAction SilentlyContinue) {
    Remove-Item -Recurse -Force "$tizen_tmp"
  }

  if ($env:debug) {
    Set-PSDebug -Trace 0
  }
}