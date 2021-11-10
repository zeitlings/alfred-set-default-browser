import Foundation
import ApplicationServices
import ArgumentParser

let HTTP_FLAG = URL(string: "http:")! as CFURL

struct Command: ParsableCommand {
	@Flag(help: "Write browser info to console")
	var print = false
	
	@Argument(help: "The bundle-Id of the new default browser, e.g. com.google.Chrome. Alternatively, enter the name, e.g. Brave")
	var bundleId: String?
	
	mutating func run() throws {
		try handleCommand(bundleId: bundleId, printBundles: print)
	}
}

extension Command {
	func handleCommand(bundleId: String?, printBundles: Bool = false) throws -> Void {
		let standardOutput: FileHandle = .standardOutput
		guard let bundleId = bundleId else {
			standardOutput.write("No bundle-Id input.")
			return
		}
		let applicationPaths: [URL] = getApplicationURLs()
		let defaultBrowserPath: URL? = getDefaultBrowserURL()
		let browserBundles: [BrowserBundle] = applicationPaths
			.intoBrowserBundles(currentDefault: defaultBrowserPath)

		if printBundles {
			browserBundles.forEach { $0.println() }
		}
		
		if let newDefault: BrowserBundle = browserBundles
			.first(where: {
				$0.id == bundleId
				|| $0.name.lowercased().contains(bundleId.lowercased())
			})
		{
			setDefault(browser: newDefault, fileHandle: standardOutput)
			
		} else {
			let options: String = browserBundles.map { $0.description }.joined(separator: "\n")
			let error: String = "Browser '\(bundleId)' is not installed. Options:\n\(options)"
			standardOutput.write(error)
		}
	}
}

extension Command {
	/// Get the file system path of applications that can open "http:"-URLs
	/// - Returns: The URLs of elligible browsers and other applications.
	func getApplicationURLs() -> [URL] {
		let urls = LSCopyApplicationURLsForURL(HTTP_FLAG, .all)?.takeRetainedValue() as? [URL]
		return urls == nil ? [] : .init(Set(urls!))
	}

	/// Get the file system path of the current application that by default opens "http:"-URLs
	/// - Returns: The URL of the default browser.
	func getDefaultBrowserURL() -> URL? {
		LSCopyDefaultApplicationURLForURL(HTTP_FLAG, .all, nil)?.takeRetainedValue() as URL?
	}
	
	func setDefault(browser bundle: BrowserBundle, fileHandle standardOutput: FileHandle) {
		if bundle.isDefault {
			standardOutput.write("\(bundle.name) (\(bundle.id)) is already the default browser")
		} else {
			LSSetDefaultHandlerForURLScheme("http" as CFString, bundle.id as CFString)
			standardOutput.write("\(bundle.name) (\(bundle.id)) is now the default browser")
		}
	}
}

Command.main()



// ===---------------------------------------------=== //
// Utils & Helpers
// ===---------------------------------------------=== //

struct BrowserBundle {
	var id: String
	var name: String
	var url: URL
	var isDefault = false
}

extension BrowserBundle {
	var description: String { "\(isDefault ? "*" : " ") \(id) (\(name))" }
	func println() { print(description) }
}


extension FileHandle: TextOutputStream {
	public func write(_ string: String) {
		if let data: Data = string.data(using: .utf8) {
			write(data)
		}
	}
}

extension Bundle {
	var name: String? {
		(infoDictionary?["CFBundleDisplayName"] ?? infoDictionary?["CFBundleName"]) as? String
	}
}

extension Array where Element == URL {
	func intoBrowserBundles(currentDefault defaultBrowserPath: URL?) -> [BrowserBundle] {
		reduce(into: [], { partialResult, url in
			if let b = Bundle(url: url), b.bundleIdentifier != nil {
				partialResult.append(
					BrowserBundle(
						id: b.bundleIdentifier!,
						name: b.name ?? "unknown",
						url: b.bundleURL,
						isDefault: b.bundleURL == defaultBrowserPath
					)
				)
			}
		})
		.sorted(by: { $0.id > $1.id })
	}
}
