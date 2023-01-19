//
//  set_default_browser.swift
//
//  Created by Patrick Sy on 19/01/2023.
//  Credit to J.W. Bargsten: https://bargsten.org/wissen/publish-swift-app-via-homebrew/#lab-section-1
//

import Foundation

@main
public struct Workflow {
	static let args: [String] = CommandLine.arguments
	static let stdOut: FileHandle = .standardOutput
	static let httpFlag = URL(string: "http:")! as CFURL
	static let options: NSString.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
	
    public static func main() {
		
		guard let bundleID: String = args.indices.contains(1) ? args[1] : nil else {
			stdOut.write(Data("No bundle identifier was specified as argument.".utf8))
			exit(.failure)
		}
		
		let browsersUsable: [URL] = getApplicationURLs()
		let browserDefault: URL? = getDefaultBrowserURL()
		let browserBundles: [BrowserBundle] = browsersUsable
			.intoBrowserBundles(currentDefault: browserDefault)
		
		guard
			let newDefault: BrowserBundle = browserBundles.first(where: {
				$0.id == bundleID
				|| $0.name.range(of: bundleID, options: options) != nil
			})
		else {
			let options: String = browserBundles.map({ $0.description }).joined(separator: "\n")
			let message: String = "Browser '\(bundleID)' is not installed. Options:\n\(options)"
			stdOut.write(Data(message.utf8))
			exit(.failure)
		}
		
		setDefault(browser: newDefault)
        
    }
}

extension Workflow {
	/// Get the file system path of applications that respond to http
	///  - Returns: The URLs of compatible browsers and other applications
	static func getApplicationURLs() -> [URL] {
		guard let urls: [URL] = LSCopyApplicationURLsForURL(httpFlag, .all)?.takeRetainedValue() as? [URL] else {
			return []
		}
		return .init(Set(urls))
	}

	static func getDefaultBrowserURL() -> URL? {
		LSCopyDefaultApplicationURLForURL(httpFlag, .all, nil)?.takeRetainedValue() as URL?
	}
	
	static func setDefault(browser bundle: BrowserBundle) {
		if bundle.isDefault {
			//let msg: Data = Data("\(bundle.name) already is the default browser".utf8)
			let msg: Data = Data("same,\(bundle.name),already is the default browser".utf8)
			stdOut.write(msg)
			exit(.success)
		} else {
			LSSetDefaultHandlerForURLScheme("http" as CFString, bundle.id as CFString)
			//let msg: Data = Data("\(bundle.name) is now the default browser".utf8)
			let msg: Data = Data("success,\(bundle.name),is now the default browser".utf8)
			stdOut.write(msg)
			exit(.success)
		}
	}
}


extension Workflow {
	enum ExitCode { case success, failure }
	static func exit(_ code: ExitCode) -> Never {
		switch code {
		case .success: Darwin.exit(EXIT_SUCCESS)
		case .failure: Darwin.exit(EXIT_FAILURE)
		}
	}
}


// ===---------------------------------------------=== //
// MARK: Helpers
// ===---------------------------------------------=== //

struct BrowserBundle {
	let id: String
	let name: String
	let url: URL
	let isDefault: Bool
	var description: String { "\(isDefault ? "*" : " ") \(id) (\(name))" }
}

extension Bundle {
	var name: String? { (infoDictionary?["CFBundleDisplayName"] ?? infoDictionary?["CFBundleName"]) as? String }
}

extension Array where Element == URL {
	func intoBrowserBundles(currentDefault defaultBrowserPath: URL?) -> [BrowserBundle] {
		return reduce(into: [], {
			if let bundle: Bundle = .init(url: $1),
			   let bID: String = bundle.bundleIdentifier
			{
				let name: String = bundle.name ?? "unknown"
				let url: URL = bundle.bundleURL
				let isDefault: Bool = bundle.bundleURL == defaultBrowserPath
				let bb: BrowserBundle = .init(id: bID, name: name, url: url, isDefault: isDefault)
				$0.append(bb)
			}
		}).sorted(by: { $0.id > $1.id })
	}
}
