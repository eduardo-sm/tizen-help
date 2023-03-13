Tizen Help
==========

Tizen help is a wrapper for the Tizen Studio CLI Tools that aim to simplify the developmen
process by creating a set of simple instructions for common actions like connect, install,
debug and package tizen applications (wgt).

# Installation
Copy the script `tizen-help` to a directory in your path. A common place is ~/.local/bin:

```bash
  cp tizen-help ~/.local/bin
```

Optionally you can create a simlink to tizen-help with a sorter name like `th`

```bash
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

- syntax:      Example of how to use the tizen and sdb commands for common use cases.

- info:        Print the current value of the environment variables and the result of tizen version and sdb version.

- connect:     Connects to a device. Accepts the device IP as argument or the environment variable SAMSUNG_DEVICE_IP.

- disconnect:  Disconnects a device from the sdb deamon. Same arguments as the connect command.

- build:       Call the `tizen build-web` command and put the results in `.buildResults` subdirectory.

- package:     Create a WGT file. It will use the default certificate configured in Tizen Studio - Certificate Manager.

- install:     Install a WGT file (Path to file as argument). Requires to be connected to a device.

- uninstall:   Uninstall a WGT file (Path ro file or appId as argument). Old devices may not support this command.

- debug:       Launch an application in debug mode. Opens the browser if CHROMIUM environment varibale is set.


## Help output


```bash
tizen-help help
  
    Tizen helper for CLI use
  
    Commands:
      - install       > Install the app provided [wgt-path] in the target tv.
      - uninstall     > Uninstall the app in the tv. It accepts both [app-id] or [wgt-path].
      - debug         > Start a debug session of the app that matches the [app-id] or [wgt-path]
                        If CHROMIUM variable exitst, it will launch it the browser
                        If DISABLE_WEB_SECURITY is "true", it will use disable-web-security flag.
      - build         > Builds a tizen project in the specified directory
                        and outs the results in .buildResult located in the specified directory.
      - package       > Package a tizen app (wgt) in the directory specified.
      - connect       > Connect to the TV using the provided IP or the IP in SAMSUNG_DEVICE_IP variable.
      - disconnect    > Disconnect from the TV using the provided IP or the IP in SAMSUNG_DEVICE_IP variable.
      - appid         > Show the [app-id] from a given [wgt] file.
      - info          > Show current value of CHROMIUM and SAMSUNG_DEVICE_IP variables
                        as well as the result of "tizen version" and "sdb version".
      - syntax        > Show syntax help of common uses cases of tizen cli.
      - help          > Prints this message.
  
  Usage:
      tizen-help install [ wgt-path ]
      tizen-help uninstall [ app-id | wgt-path ]
      tizen-help debug [ app-id | wgt-path ]
      tizen-help build [ path-to-build ]
      tizen-help package [ path-to-package ]
      tizen-help connect [device-ip]
      tizen-help disconnect [device-ip]
      tizen-help appid [ wgt-path ]
      tizen-help info
      tizen-help syntax
      tizen-help help
  
  Options:
      -h | --help                   Print this message
  
    Environment variables:
      - CHROMIUM                    Path of the browser executable
      - SAMSUNG_DEVICE_IP           IP Address of the device to connect to
      - DISABLE_WEB_SECURITY        Start the browser with web security disabled [ true | false ]
```

# Compatibility

This wrapper is compatible with most bash interpreters including windows (Git bash and WSL).

## Windows Caveats

For Git bash, it will wrap tizen and sdb and use `cmd.exe` to execute them.

On WSL it will use first the native Tizen CLI Tools for Linux if available and then
fallback to the windows tools. If using the windows tools, the commands will be executed by `cmd.exe`
and if working in the Linux filesystem, all the operations will be defaulted to the temporal
directory of the windows user.

# Dependencies

- Tizen Studio CLI Tools. More specifically `tizen` and `sdb` commands. Both need to be available in your path.

# Configuration

The script can be configured with 3 environment variables

CHROMIUM:                   Path of the browser executable. It can be chromium or other browser.

SAMSUNG_DEVICE_IP:          IP Address of the device to connect to. E.g. 192.168.1.50

DISABLE_WEB_SECURITY:       Start the browser with web security disabled "[ true | false or anything else ]" (Chromium based browsers only).

# Documentation

For more information read the confluence page for [tizen-help](https://accedobroadband.jira.com/wiki/spaces/ATEC/pages/2646573120/Tizen+CLI+helper+tizen-help).
