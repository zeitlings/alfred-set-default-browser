# Set Default Browser

Alfred workflow to set the default browser. [[Download Here]](https://github.com/zeitlings/alfred-set-default-browser/releases/tag/v1.1.0)

Add the browsers that you are missing to the list filter, and provide the bundle identifiers for them. Instead of adding the bundle identifier for, e.g. Brave Browser (`com.brave.Browser`), just providing the name (Brave) should also work. This workflow has not been thoroughly tested. 

 __Some Popular Browsers__
 
```
 Name			| Bundle Identifier
--------------------------------------------
Safari			| com.apple.Safari
Google Chrome		| com.google.Chrome
Firefox			| org.mozilla.firefox
Opera			| com.operasoftware.Opera
Brave Browser		| com.brave.Browser
Tor Browser		| org.torproject.torbrowser
Microsoft Edge		| com.microsoft.edgemac
Vivaldi			| com.vivaldi.Vivaldi
```
--------

The executable is largely a rewrite of [this code by "J.W. Bargsten"](https://bargsten.org/wissen/publish-swift-app-via-homebrew/#lab-section-1) and adapted to work well with Alfred. It is a universal binary and will run on Macs with either ARM or Intel processors. If for some reason it does not work for you, or if you do not want to run an opaque executable, recompile and replace the included version. (Right-click the workflow and select `Reveal in Finder` for the location).


## Recompile

In your terminal:

```
mkdir set-default-browser
cd set-default-browser
swift package init --type executable
```

This will generate the following structure for you:  
```
.
├── Package.swift
├── README.md
├── Sources
│   └── set_default_browser
│       └── set_default_browser.swift
└── Tests
    └── set_default_browserTests
        └── set_default_browserTests.swift
```

Replace the contents of `main.swift` with [the contents of the included main.swift](https://github.com/zeitlings/alfred-set-default-browser/blob/main/main.swift).  
Replace the contents of `Package.swift` with [the contents of the included Package.swift](https://github.com/zeitlings/alfred-set-default-browser/blob/main/Package.swift)

In your terminal, run:

```
swift build -c release
```

The executable is located in `.build/release/` (hidden folder) and is called `set_default_browser`. `release` is a symbolic link and, in my case, the path reads: `/.build/arm64-apple-macosx/release/set_default_browser`. Depending on your system, this might differ.

Copy the executable and replace the version that comes with the workflow.
