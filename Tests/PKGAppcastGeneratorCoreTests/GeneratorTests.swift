import XCTest
import PKGAppcastGeneratorCore
import PizzaMacros

class GeneratorTests: XCTestCase {
	func testGenerateAppcastFromScratch() throws {
		let directory = Bundle.module.url(forResource: "JSON", withExtension: nil, subdirectory: "TestResources")!
		let jsonExpectationURL = Bundle.module.url(forResource: "expectedJSONResult", withExtension: "xml", subdirectory: "TestResources")!
		let jsonExpectation = try XMLDocument(contentsOf: jsonExpectationURL)

		let data = try PKGAppcastGeneratorCore.generateAppcast(
			fromContentsOfDirectory: directory,
			previousAppcastData: nil,
			channelTitle: "Appcast",
			signatureGenerator: { _ in "Secured! jk"},
			downloadURLPrefix: #URL("https://he.ho.hum/updates/"))

		let xmlDoc = try XMLDocument(data: data)
		Self.cleanXMLDates(in: xmlDoc)

		XCTAssertEqual(xmlDoc, jsonExpectation)
	}

	func testAppendAppcast() throws {
		let directory = Bundle.module.url(forResource: "JSONAppend", withExtension: nil, subdirectory: "TestResources")!
		let jsonStarterURL = Bundle.module.url(forResource: "expectedJSONResult", withExtension: "xml", subdirectory: "TestResources")!
		let jsonStarterData = try Data(contentsOf: jsonStarterURL)
		let jsonAppendExpectationURL = Bundle.module.url(forResource: "expectedJSONAppendResult", withExtension: "xml", subdirectory: "TestResources")!
		let jsonAppendExpectation = try XMLDocument(contentsOf: jsonAppendExpectationURL)

		let data = try PKGAppcastGeneratorCore.generateAppcast(
			fromContentsOfDirectory: directory,
			previousAppcastData: jsonStarterData,
			channelTitle: "Appcast",
			signatureGenerator: { _ in "Secured! jk"},
			downloadURLPrefix: #URL("https://he.ho.hum/updates/"))

		let xmlDoc = try XMLDocument(data: data)
		Self.cleanXMLDates(in: xmlDoc)

		XCTAssertEqual(xmlDoc, jsonAppendExpectation)
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
