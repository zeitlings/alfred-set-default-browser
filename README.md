# alfred-set-default-browser
An Alfred workflow for setting the default browser.

Add the browsers you want as options to the list (within Alfred App) and provide their bundle identifiers. By default, the list contains entries for Safari and Brave. Instead of adding the bundle identifier for, e.g. Brave Browser (com.brave.Browser), you can also just provide the name (Brave), which should also work. None of this is thoroughly tested.

The executable is basically a rewrite of [this code by "jw bargsten"](https://bargsten.org/wissen/publish-swift-app-via-homebrew/#lab-section-1) and adjusted to work nicely with Alfred.
It was compiled on a MacBook with ARM Processor (M1 Pro). Should it not work for you or should you not want to run an opaque executable, just recompile it and replace the included version. (Right-click the Workflow and select `Reveal in Finder` for the location.)

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
│       └── main.swift
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
