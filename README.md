# SFML-nuget_builder
PowerShell script to generate NuGet packages for SFML.

### You can download pre-generated packages [here](https://github.com/xapdkop/sfml-nuget) (look in [releases](https://github.com/xapdkop/sfml-nuget/releases))

# Prerequisite

To generate packages you need:
- The CoApp tools: [Official website](http://coapp.org) | [Download page](http://coapp.org/pages/releases.html)
- Internet connection (or just you may preload needed packages and put them into the *distfiles/* folder)

# How to

You just have to run the sfml-nuget.ps1 script in a PowerShell instance.
It will download each needed files and output nupkg files in the "repository" folder.
Also you can customize script if you want.

# Customization

You can customize packages by changing this params:
- `$pkg_prefix` to change packages' names **(Don't remove the reference to the SFML!)**
- `$keep_sources` to keep or delete source files, **true** by default
- `$keep_autopkg` to keep or delete autopkg files, **false** by default
- `$use_old_include_workaround` to enable old workaround for include folder in *system* module (**may be** safer then new one, but you need to manually delete file "delete.me" from include folder in *system* module; **false** by default [uses new workaround])
- `$add_docs` to add the SFML's documentation (it would be added and available only in *system* module), **false** by default
- `$sfml_owners` to change packages' owner(s)
- `$sfml_tags` to customize tags
- `$sfml_module_list` to choose modules you need
- `$sfml_version` to choose packages version (min - 2.2)
- `$sfml_platforms`, `$sfml_toolchains`, `$sfml_configurations` - for advanced users

## You should know what your are changing!!!