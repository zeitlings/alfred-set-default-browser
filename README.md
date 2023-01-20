# Set Default Browser

[Alfred](https://www.alfredapp.com/) workflow to set the default browser. 
- Script Version [[Download Here]](https://github.com/zeitlings/alfred-set-default-browser/releases/tag/v1.1.1) (preferred)


Add the browsers that you are missing to the list filter and provide the bundle identifiers for them. Instead of adding the bundle identifier for, e.g. Brave Browser `com.brave.Browser`, just providing the name (Brave) should also work. This has not been thoroughly tested. 


## Script Version

v1.1.1 dispenses with the executable entirely. The code runs directly in Alfred's Run Script workflow object. There is no noticable performance penalty and no manual compilation or `chmod +x` permissions are required. The code is largely a rewrite of [this code by "J.W. Bargsten"](https://bargsten.org/wissen/publish-swift-app-via-homebrew/#lab-section-1) and adapted to work well with Alfred.


## Compiled Version

<details>

  <summary>Compiled Version (command line)</summary>


The executable can be used to change the default browser from the command line: `./set_default_browser tor`


### Recompile

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

Replace the contents of `set_default_browser.swift` with [the contents of the included main.swift](https://github.com/zeitlings/alfred-set-default-browser/blob/main/main.swift).  
Replace the contents of `Package.swift` with [the contents of the included Package.swift](https://github.com/zeitlings/alfred-set-default-browser/blob/main/Package.swift)

In your terminal, run:

```
swift build -c release
```

The executable is located in `.build/release/` (hidden folder) and is called `set_default_browser`. `release` is a symbolic link and, in my case, the path reads: `/.build/arm64-apple-macosx/release/set_default_browser`. Depending on your system, this might differ.

Copy the executable and replace the version that comes with the workflow.

</details>


---

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
