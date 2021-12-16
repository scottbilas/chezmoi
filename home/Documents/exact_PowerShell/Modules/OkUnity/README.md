# ScottBilas.Unity PowerShell Module

Purpose: support common workflows in Unity

## Setup

To get validation on the ~/.config/OkUnity/config.yaml file, be sure to `scoop install pajv`.

## Run Unity

* Choose an EXE
  * Match something I already have on my machine (latest beta or released, or give me a chooser)
  * Whatever this project wants, or use a matcher to select something close if I don't have it
  * A specific (hash, full version name) or partial version name (just the year and dot.., or "latest beta" perhaps)
  * Warnings about debug vs release, or mismatched project causing an upgrade (does Unity do this already? or was it the Hub?)
* Set env and command line etc.
  * Standard flags I always set, like mixed stacks and log output
  * Make Unity's flags visible with tab completion (something like Crescendo would do..except Crescendo doesn't seem to support parameterized exe location..)
  * Support an individual project's extensions to tab completion for any command line flags the project supports
  * PSReadLine support for tabbing through matching discovered unity versions
* Support the exe run
  * Start separate job watching unity.exe and monitoring pmip files from it, holding handle open and copy on process exit
  * Hub killing
  * Log rotation
  * Automatic bringing to front of an existing Unity (avoid Unity's stupid handling of this)

## Install Unity

* Manage Unity installations
  * Download with cli downloader (specific version or fuzzy, but still expanded to full version name+hash for install folder)
  * Upgrade an install (add symbols to an existing installation)
  * Install into or remove from Hub (clean up Hub install tracker json)
  * Download and install a public release (invoke-webrequest https://unity3d.com/get-unity/download/archive and rx `https://[^"]+UnitySetup(64)?-(\d+\.\d+\.\w+)\.exe`)

## Utilities

* Detection of whether a folder/file is in a Unity project and find the project root
* Detection of a Unity project's version
* Detection of various build related info, especially versions related to Unity and its components (like mono)
* Enumeration of builds - cli-downloaded, Hub-installed, download site-installed, locally built trunk, in-project toolchain (like a2ds uses) etc.
* Crescendo wrapper for cli downloader
* Some kind of caching into a json to avoid re-scanning all the folders every time
* oh-my-posh prompt support for when within a Unity project (show version number etc.)
