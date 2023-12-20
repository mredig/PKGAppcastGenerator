import XCTest
import PKGAppcastGeneratorCore
import PizzaMacros
import ZIPFoundation

class GeneratorTests: XCTestCase {
	func testGenerateAppcastJSONFromScratch() throws {
		let directory = Bundle.module.url(forResource: "JSON", withExtension: nil, subdirectory: "TestResources")!
		let jsonExpectationURL = Bundle.module.url(forResource: "expectedJSONResult", withExtension: "xml", subdirectory: "TestResources")!
		let jsonExpectation = try XMLDocument(contentsOf: jsonExpectationURL)

		let data = try PKGAppcastGeneratorCore.generateAppcast(
			fromContentsOfDirectory: directory,
			previousAppcastData: nil,
			channelTitle: "Appcast",
			downloadsLink: nil,
			signatureGenerator: { _ in "Secured! jk"},
			downloadURLPrefix: #URL("https://he.ho.hum/updates/"))

		let xmlDoc = try XMLDocument(data: data)
		Self.cleanXMLDates(in: xmlDoc)

		XCTAssertEqual(xmlDoc, jsonExpectation)
	}

	func testGenerateAppcastJSONViaAppend() throws {
		let directory = Bundle.module.url(forResource: "JSONAppend", withExtension: nil, subdirectory: "TestResources")!
		let jsonStarterURL = Bundle.module.url(forResource: "expectedJSONResult", withExtension: "xml", subdirectory: "TestResources")!
		let jsonStarterData = try Data(contentsOf: jsonStarterURL)
		let jsonAppendExpectationURL = Bundle.module.url(forResource: "expectedJSONAppendResult", withExtension: "xml", subdirectory: "TestResources")!
		let jsonAppendExpectation = try XMLDocument(contentsOf: jsonAppendExpectationURL)

		let data = try PKGAppcastGeneratorCore.generateAppcast(
			fromContentsOfDirectory: directory,
			previousAppcastData: jsonStarterData,
			channelTitle: "Appcast",
			downloadsLink: nil,
			signatureGenerator: { _ in "Secured! jk"},
			downloadURLPrefix: #URL("https://he.ho.hum/updates/"))

		let xmlDoc = try XMLDocument(data: data)
		Self.cleanXMLDates(in: xmlDoc)

		XCTAssertEqual(xmlDoc, jsonAppendExpectation)
	}

	func testGenerateAppcastZipFromScratch() throws {
		let directory = Bundle.module.url(forResource: "Zips", withExtension: nil, subdirectory: "TestResources")!
		let zipsExpectationURL = Bundle.module.url(forResource: "expectedZipsResult", withExtension: "xml", subdirectory: "TestResources")!
		let zipsExpectation = try XMLDocument(contentsOf: zipsExpectationURL)

		let data = try PKGAppcastGeneratorCore.generateAppcast(
			fromContentsOfDirectory: directory,
			previousAppcastData: nil,
			channelTitle: "Appcast",
			downloadsLink: URL(string: "https://he.ho.hum/myapps/downloads"),
			signatureGenerator: { _ in "Secured! jk"},
			downloadURLPrefix: #URL("https://he.ho.hum/updates/"))

		let xmlDoc = try XMLDocument(data: data)
		Self.cleanXMLDates(in: xmlDoc)

		XCTAssertEqual(xmlDoc, zipsExpectation)
	}

	func testGenerateAppcastZipViaAppend() throws {
		let directory = Bundle.module.url(forResource: "ZipsAppend", withExtension: nil, subdirectory: "TestResources")!
		let zipsStarterURL = Bundle.module.url(forResource: "expectedZipsResult", withExtension: "xml", subdirectory: "TestResources")!
		let zipsStarterData = try Data(contentsOf: zipsStarterURL)
		let zipsExpectationURL = Bundle.module.url(forResource: "expectedZipsAppendResult", withExtension: "xml", subdirectory: "TestResources")!
		let zipsExpectation = try XMLDocument(contentsOf: zipsExpectationURL)

		let data = try PKGAppcastGeneratorCore.generateAppcast(
			fromContentsOfDirectory: directory,
			previousAppcastData: zipsStarterData,
			channelTitle: "Appcast",
			downloadsLink: URL(string: "https://he.ho.hum/myapps/downloads"),
			signatureGenerator: { _ in "Secured! jk"},
			downloadURLPrefix: #URL("https://he.ho.hum/updates/"))

		let xmlDoc = try XMLDocument(data: data)
		Self.cleanXMLDates(in: xmlDoc)

		XCTAssertEqual(xmlDoc, zipsExpectation)
	}

	static func cleanXMLDates(in xmlDoc: XMLDocument) {
		var theNode: XMLNode? = xmlDoc

		while let current = theNode {
			theNode = current.next

			guard current.name == "pubDate" else { continue }
			theNode?.stringValue = PKGAppcastGeneratorCore.dateFormatter.string(from: .distantPast)
		}
	}
}
