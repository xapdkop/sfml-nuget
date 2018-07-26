# sfml-nuget_builder
Create NuGet packages for SFML.

### You can download pre-generated packages [here](https://github.com/xapdkop/sfml-nuget) (look in [releases](https://github.com/xapdkop/sfml-nuget/releases))

# Prerequisite

- The CoApp tools: [Official website](http://coapp.org) | [Download page](http://coapp.org/pages/releases.html)

# How to

You just have to run the sfml-nuget.ps1 script in a PowerShell instance.
It will download each needed files and output nupkg files in the "repository" folder.
Also you can customize script if you want.

# Customization

You can customize packages by changing this params:
- `$pkg_prefix` to change packages' names **(Don't remove the reference to the SFML)**
- `$pkg_owner` to change packages' owner
- `pkg_tags` to customize tags
- `$keep_sources` to keep or delete source files, **true** by default
- `$keep_autopkg` to keep or delete autopkg files, **false** by default
- `$use_old_include_workaround` to enable old workaround for include folder in system module (**may be** safer then new one, but you need to manually delete file "delete.me" from include folder in system module; **false** by default [uses new workaround])

### Optional :
You can modify some variables to select the SFML version, generate only specific modules, etc...

## You should know what your are changing!!!