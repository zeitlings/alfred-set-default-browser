#!/usr/bin/swift
//
//  browser.swift
//
//  Created by Patrick Sy on 19/01/2023.
//  - v2 on 05/11/2024
//

import AppKit

struct Workflow {
	private static let args: ArraySlice<String> = CommandLine._arguments
	private static let stdOut: FileHandle = .standardOutput
	private static let stdErr: FileHandle = .standardError
	@Env(key: "alfred_debug") private static var isDebugPanelOpen: Bool
	@Env(key: "browser_bundleid") private static var runtimeBundleID: String?
	@Env(key: "alfred_workflow_bundleid") private static var workflowBundleID: String?
	@Env(key: "blacklist", separator: "\n") private static var blacklist: [String]

	static func main() {
	    let browsers: [BrowserBundle] = Workflow.browsers
		guard
			let bundleID: String = runtimeBundleID,
			let browser: BrowserBundle = browsers
				.first(where: { $0.id == bundleID })
		else {
		    logInformation(of: browsers)
			list(filter: args, browsers)
		}
		setAsDefault(browser)
		finish(with: browser)
	}
}

extension Workflow {

	private static func list(filter arguments: ArraySlice<String>, _ browsers: [BrowserBundle]) -> Never {
		let argument: String? = arguments[safe: 1]
		let items: [Item] = browsers
		    .map(\.alfredItem)
			.filter({ item in
				argument.map { item.title.hasSubstring($0) } ?? true
			})
		Workflow.return(.init(items: items))
	}

	private static func logInformation(of browsers: [BrowserBundle]) {
		guard isDebugPanelOpen else { return }
		log(browsers.eligibleBrowserDescription)
		log("\nCommand Line Arguments:\n")
		for (idx, arg) in Self.args.enumerated() {
			log(" ~ [\(idx)]: <\(arg)>\n")
		}
	}

	private static let browsers: [BrowserBundle] = {
		let browsersUsable: [URL] = getApplicationURLs()
		let browserDefault: URL? = getDefaultBrowserURL()
		let browserBundles: [BrowserBundle] = browsersUsable
			.intoBrowserBundles(currentDefault: browserDefault)
			.filter({ !blacklist.contains($0.name) })
			.filter({ $0.isUsable })
		return browserBundles
	}()

	private static func finish(with browser: BrowserBundle) {
		external(
			id: "did.set",
			argument: "success,\(browser.name),is now the default browser"
		)
	}
}

extension Workflow {

	private static func getApplicationURLs() -> [URL] {
		let urls1: [URL] = NSWorkspace.shared.urlsForApplications(toOpen: URL(string: "https:")!)
		let urls2: [URL] = NSWorkspace.shared.urlsForApplications(toOpen: URL(string: "http:")!)
		let urls3: [URL] = NSWorkspace.shared.urlsForApplications(toOpen: .html)
		let intersection: Set<URL> = Set(urls1).intersection(urls2).intersection(urls3)
		return .init(intersection)
	}

	private static func getDefaultBrowserURL() -> URL? {
		NSWorkspace.shared.urlForApplication(toOpen: URL(string: "http:")!)
	}

	private static func setAsDefault(_ browser: BrowserBundle) {
	   NSWorkspace.shared.setDefaultApplication(at: browser.url, toOpenURLsWithScheme: "http")
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

	private static func log(_ string: String) {
		if isDebugPanelOpen {
			stdErr.write(Data(string.utf8))
		}
	}
}

extension Workflow {

	private static func `return`(_ response: Response, nullMessage: String = "No results...") -> Never {
		var response: Response = response
		if response.items.isEmpty {
			response = .init(items: [.with({
				$0.title = nullMessage
				$0.icon = ["path":"icons/info.png"]
				$0.valid = false
			})])
		}
		stdOut.write(response.encoded())
		exit(.success)
	}

	private static func external(id triggerId: String, argument: String, process: Process = .init()) -> Never {
		guard
			let bundleId: String = workflowBundleID,
			let encoded: String = argument.addingPercentEncoding(
				withAllowedCharacters: .alphanumerics
			)
		else {
			let errorInfo: String = "Failure preparing for External Trigger"
			let errorMessage: String = "BundleID: \(workflowBundleID ?? "Must be set"). TriggerID \(triggerId)"
			log(errorInfo)
			log(errorMessage)
			exit(.failure)
		}
		let command: String = "open alfred://runtrigger/\(bundleId)/\(triggerId)/?argument=\(encoded)"
		process.bash(with: command)
		exit(.success)
	}
}

// ===---------------------------------------------=== //
// MARK: Helpers
// ===---------------------------------------------=== //

fileprivate let controlSchemes: Set<String> = ["https","http"] // ["https", "file", "http"]
fileprivate let illegalScheme: String = "feed"

internal struct BrowserBundle {
	let id: String
	let url: URL
	let name: String
	let isDefault: Bool
	let icon: String
	let supportedSchemes: Set<String>
	var isUsable: Bool {
	   controlSchemes.isSubset(of: supportedSchemes)
				&& !supportedSchemes.contains(illegalScheme)
	}
	var description: String {
		let filler1: String = String(repeating: " ", count: max(30 - (id.count), 1))
		let filler2: String = String(repeating: " ", count: max(max((50 - filler1.count), 1) - (id.count + name.count), 1))
		let base: String = "\(isDefault ? " *" : "  ") \(id)\(filler1)|\(filler2)\(name)"
		return "\(base) → \(url.path(percentEncoded: false))"
	}

	var alfredItem: Item {
		.with {
			$0.uid = id
			$0.title = isDefault ? "〉\(name)" : name
			$0.icon = ["path":icon]
			$0.subtitle = url.path(percentEncoded: false)
			let arg: String? = isDefault
			    ? "same,\(name),already is the default browser"
			    : "set,\(id)"
			$0.arg = arg
			if !isDefault {
				$0.cmdshift = Modifier(
					arg: "blacklist,\(name)",
					subtitle: "⭕️ Add to Blacklist"
				)
			}
		}
	}
}

extension Array where Element == URL {
	func intoBrowserBundles(currentDefault defaultBrowserPath: URL?) -> [BrowserBundle] {
		return reduce(into: [], {
			if let bundle: Bundle = .init(url: $1),
			   let id: String = bundle.bundleIdentifier,
			   let name: String = bundle.name,
			   let iconFile: String = bundle.infoDictionary?["CFBundleIconFile"] as? String
			{
				let url: URL = bundle.bundleURL
				$0.append(BrowserBundle(
					id: id,
					url: url,
					name: name,
					isDefault: url == defaultBrowserPath,
					icon: url.appIconPath(iconFile: iconFile),
					supportedSchemes: bundle.supportedSchemes
				))
			}
		}).sorted(by: { $0.name < $1.name })
	}
}

// MARK: Environment
@propertyWrapper
struct Env<T> {
	let key: String
	let defaultValue: T
	let transform: (String) -> T?

	var wrappedValue: T {
		guard let value = ProcessInfo.processInfo.environment[key] else {
			return defaultValue
		}
		return transform(value) ?? defaultValue
	}

	init(key: String, default: T, transform: @escaping (String) -> T?) {
		self.key = key
		self.defaultValue = `default`
		self.transform = transform
	}
}

extension Env where T == Bool {
	init(key: String, default: Bool = false) {
		self.init(key: key, default: `default`) { $0 == "1" }
	}
}

extension Env where T == String? {
	init(key: String) {
		self.init(key: key, default: nil) { $0 }
	}
}

extension Env where T == [String] {
	init(key: String, separator: Character = "\n") {
		self.init(key: key, default: []) {
			$0.split(separator: separator).map(String.init)
		}
	}
}

// MARK: Extensions

extension Bundle {
	var name: String? {
		(infoDictionary?["CFBundleDisplayName"] ?? infoDictionary?["CFBundleName"]) as? String
	}
	private var urlTypes: [[String: Any]]? {
		infoDictionary?["CFBundleURLTypes"] as? [[String: Any]]
	}
	var supportedSchemes: Set<String> {
		urlTypes?
			.compactMap({ $0["CFBundleURLSchemes"] as? [String] })
			.reduce([], +)
			.into() ?? []

	}
}

extension Array where Element == String {
	func into() -> Set<String> { Set(self) }
}

extension ArraySlice where Element == String {
	subscript(safe index: Int) -> String? {
		get {
			let element: String? = self.indices.contains(index) ? self[index].trimmed : nil
			return (element ?? "").isEmpty ? nil : element
		}
		set { preconditionFailure() }
	}
}

extension Array where Element == BrowserBundle {
	var eligibleBrowserDescription: String {
		let divider: String = .init(repeating: "=", count: 55)
		let options: String = sorted(by: { $0.name.count < $1.name.count })
			.map({ $0.description })
			.joined(separator: "\n")
		var description: String = "\nEligible Applications:\n\(options)\n"
		if let currentDefault: BrowserBundle = first(where: { $0.isDefault }) {
			let currentSchemesDescription: String = currentDefault.supportedSchemes.joined(separator: ", ")
			let currentDefaultSchemes: String = "\n\(currentDefault.name) Schemes: [\(currentSchemesDescription)]"
			description = currentDefaultSchemes + "\n" + divider + description
		}
		return "~\n" + divider + description + divider
	}
}

internal extension StringProtocol {
	var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
	func hasSubstring(_ substring: String) -> Bool {
		range(of: substring, options: .caseInsensitive) != nil
	}
}

internal extension URL {
	func appIconPath(iconFile: String) -> String {
		let iconFile: String = iconFile.hasSuffix(".icns") ? iconFile : "\(iconFile).icns"
		return appending(components: "Contents/Resources/\(iconFile)").path(percentEncoded: false)
	}
}

internal extension CommandLine {
	static let _arguments: ArraySlice<String> = {
	   arguments.split(separator: "--").last ?? [] // drop compiler flags
	}()
}

internal extension Process {
	func bash(with command: String) -> Void {
		launchPath = "/bin/bash"
		arguments = ["-c", command]
		launch()
		waitUntilExit()
	}
}

// MARK: - Alfred

protocol Inflatable {
	init()
}

extension Inflatable {
	static func with(_ populator: (inout Self) throws -> ()) rethrows -> Self {
		var response = Self()
		try populator(&response)
		return response
	}
}

struct Modifier: Encodable {
	var arg: String
	var subtitle: String?
}

// MARK: - Codable

struct Item: Encodable, Inflatable {
	var title: String
	var uid: String? = nil
	var subtitle: String = ""
	var arg: String? = nil
	var valid: Bool = true
	var icon: [String:String]? = nil
	var cmdshift: Modifier? = nil

	private enum CodingKeys: String, CodingKey {
		case title, uid, subtitle, arg, icon, valid, mods
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(subtitle, forKey: .subtitle)
		try container.encode(title, forKey: .title)
		try container.encode(valid, forKey: .valid)
		try container.encodeIfPresent(uid, forKey: .uid)
		try container.encodeIfPresent(arg, forKey: .arg)
		try container.encodeIfPresent(icon, forKey: .icon)
		if let cmdshift = cmdshift {
			let wrapper = ["cmd+shift": cmdshift]
			try container.encode(wrapper, forKey: .mods)
		}
	}

	init(title: String) {
		self.title = title
	}

	init() {
		self.init(title: "")
	}
}
struct Response: Encodable {
	let items: [Item]
	func encoded(encoder: JSONEncoder = .init()) -> Data {
		encoder.outputFormatting = [.prettyPrinted]
		return try! encoder.encode(self)
	}
}


Workflow.main()
