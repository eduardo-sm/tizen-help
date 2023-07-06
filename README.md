Tizen Help
==========

Tizen help is a wrapper for the Tizen Studio CLI Tools that aim to simplify the developmen
process by creating a set of simple instructions for common actions like connect, install,
debug and package tizen applications (wgt).

# Installation
Copy the script `tizen-help` to a directory in your path. A common place is ~/.local/bin:

```bash
  # Ensure ~/.local/bin exists
  mkdir -p ~/.local/bin

  # Copy script to directory
  cp tizen-help ~/.local/bin
```

Optionally you can create a simlink to tizen-help with a sorter name like `th`

```bash
  cd ~/.local/bin

  # Creates a symlink to call tizen-help as th
  ln -s tizen-help th
```

## Powershell
It is possible to call this wrapper in windows machines from powershell if Git for Windows
is installed. You need to follow the steps above as well as copying the powershell wrapper `th.ps1`

```bash
  cp th.ps1 ~/.local/bin
```

The powershell wrapper will fix any windows specific path into the MSYS2 equivalent paths
and pass the arguments to the tizen-help script wrapper.

# Usage

The tizen-help wrapper provides the following commands:

- help:        General help for usage of the script.

- version:     Print tizen-help version.

- syntax:      Example of how to use the tizen and sdb commands for common use cases.

- info:        Print the current value of the environment variables and the result of tizen version and sdb version.

- connect:     Connects to a device. Accepts the device IP as argument or the environment variable SAMSUNG_DEVICE_IP.

- disconnect:  Disconnects a device from the sdb deamon. Same arguments as the connect command.

- build:       Call the `tizen build-web` command and put the results in `.buildResult` subdirectory.

- package:     Create a WGT file. It will use the default certificate configured in Tizen Studio - Certificate Manager.

- install:     Install a WGT file (Path to file as argument). Requires to be connected to a device. Optional argument device_ip.

- uninstall:   Uninstall a WGT file (Path ro file or appId as argument). Old devices may not support this command. Optional argument device_ip.

- debug:       Launch an application in debug mode. Opens the browser if CHROMIUM environment varibale is set. Optional argument device_ip.

- profile:     Sets a given profile as the active profile. If no profile is passed, it will open a menu to choose a profile.

## Help output


```bash
tizen-help help
    Tizen helper for CLI use - v1.1.0
  
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
      - profile       > Sets a profile for signing. If no profile is provided, a menu will open to choose
                        from current profiles. If fzf is available, it will be use to display the menu.
      - info          > Show current value of CHROMIUM and SAMSUNG_DEVICE_IP variables
                        as well as the result of "tizen version" and "sdb version".
      - syntax        > Show syntax help of common uses cases of tizen cli.
      - help          > Prints this message.
      - version       > Show script version.
  
  Usage:
      tizen-help install [ wgt-path ] [ device-ip ]
      tizen-help uninstall [ app-id | wgt-path ] [ device-ip ]
      tizen-help debug [ app-id | wgt-path ] [ device-ip ]
      tizen-help build [ path-to-build ]
      tizen-help package [ path-to-package ]
      tizen-help connect [device-ip]
      tizen-help disconnect [device-ip]
      tizen-help appid [ wgt-path ]
      tizen-help profile [ profile-name ]
      tizen-help info
      tizen-help syntax
      tizen-help help
      tizen-help version
  
  Options:
      -h | --help                   Print this message
      -v | --version                Print script version
  
    Environment variables:
      - CHROMIUM                    Path of the browser executable
      - SAMSUNG_DEVICE_IP           IP Address of the device to connect to
      - DISABLE_WEB_SECURITY        Start the browser with web security disabled [ true | false ]
  
    Debug errors with the script:
      > Set a debug environment variable to enable 'set -x' logs
      $ debug=true tizen-help info
  
    Examples of use:
      # Build will always create a .buildResult directory
      $ tizen-help build ./build
  
      # Package your build in a wgt. Current signing profile will be used.
      $ tizen-help package ./build/.buildResult
  
      # Install can accept a second argument to target a device. Overrides SAMSUNG_DEVICE_IP env variable.
      $ tizen-help install ./build/.buildResult/MY_APP.wgt
  
      # Debug can accept a second argument to target a device. Overrides SAMSUNG_DEVICE_IP env variable.
      $ tizen-help debug ./build/.buildResult/MY_APP.wgt
  
      # Uninstall can accept a second argument to target a device. Overrides SAMSUNG_DEVICE_IP env variable.
      $ tizen-help uninstall ./build/.buildResult/MY_APP.wgt
  
```

## Usage

**NOTE**: No specific IP is required is `SAMSUNG_DEVICE_IP` variable is set.

Build project in the `dest` directory. Output will be placed in `dest/.buildResult`.
```bash
$ tizen-help build ./dest
```

Create a wgt from the the previous build. The name of the wgt depends on config.xml.
```bash
$ tizen-help package ./dest/.buildResult
```

Connect to tv with IP 192.168.1.10
```bash
$ tizen-help connect 192.168.1.10
```
Connect to tv using `SAMSUNG_DEVICE_IP` variable
```bash
$ export SAMSUNG_DEVICE_IP=192.168.1.10
$ tizen-help connect # It will use the variable for all commands that require a target
```

Install wgt to device. 
```bash
$ tizen-help install ./dest/.buildResult/MY_APP.wgt
```

Install wgt to different device with specific IP 192.168.1.45
```bash
$ tizen-help install ./dest/.buildResult/MY_APP.wgt 192.168.1.45
```

Debug app in TV using appId.
```bash
$ tizen-help debug abcdefg.MY_APP
```

Debug app extracting appId from wgt file.
```bash
$ tizen-help debug ./dest/.buildResult/MY_APP.wgt
```
**NOTE**: Debug command prints on screen the address to inspect. You need to use a chromium based browser for debugging. The browser will open automatically if you set the `CHROMIUM` environment variable.

It is possible to target the debug session to a specific device by passing an IP as third argument.
```bash
$ tizen-help debug ./dest/.buildResult/MY_APP.wgt 192.168.1.45
```

Uninstall app. It can use either appId or extract it from wgt.
```bash
$ tizen-help uninstall ./dest/.buildResult/MY_APP.wgt 192.168.1.45
```

Disconnect from device. IP can be specified or it will default to `SAMSUNG_DEVICE_IP`.
```bash
$ tizen-help disconnect 192.168.1.45
```
**NOTE**: If all devices are disconnected, tizen-help will terminate the sdb deamon.

# Compatibility

This wrapper is compatible with most bash interpreters including windows (Git bash and WSL).

## Windows Caveats

- For Git bash, it will wrap tizen and sdb and use `cmd.exe` to execute them.

- On WSL it can use either native Tizen CLI Tools for Linux or Tizen CLI Tools for windows. The windows tools will be executed by calling the command using `cmd.exe`. To avoid issues with UNC paths (if usign windows cli) the tizen-help command will process all the commands in a temporal directory of the windows user and copy the results back to the original working directory.

# Dependencies

- Tizen Studio CLI Tools. More specifically `tizen` and `sdb` commands. Both need to be available in your path.

# Configuration

The script can be configured with 3 environment variables

CHROMIUM:                   Path of the browser executable. It can be chromium or other browser.

SAMSUNG_DEVICE_IP:          IP Address of the device to connect to. E.g. 192.168.1.50

DISABLE_WEB_SECURITY:       Start the browser with web security disabled "[ true | false or anything else ]" (Chromium based browsers only).

# Documentation

For more information read the confluence page for [tizen-help](https://accedobroadband.jira.com/wiki/spaces/ATEC/pages/2646573120/Tizen+CLI+helper+tizen-help).
