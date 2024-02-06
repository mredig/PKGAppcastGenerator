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

	func testGenerateAppcastZipWithJSONAugmentationViaAppend() throws {
		let setupDirectory = Bundle.module.url(forResource: "ZipsAppend", withExtension: nil, subdirectory: "TestResources")!
		let jsonPairedDirectory = Bundle.module.url(forResource: "ZipsAppend2", withExtension: nil, subdirectory: "TestResources")!
		let zipsStarterURL = Bundle.module.url(forResource: "expectedZipsResult", withExtension: "xml", subdirectory: "TestResources")!
		let zipsStarterData = try Data(contentsOf: zipsStarterURL)
		let zipsExpectationURL = Bundle.module.url(forResource: "expectedZipsAppend2Result", withExtension: "xml", subdirectory: "TestResources")!
		let zipsExpectation = try XMLDocument(contentsOf: zipsExpectationURL)

		let starterData = try PKGAppcastGeneratorCore.generateAppcast(
			fromContentsOfDirectory: setupDirectory,
			previousAppcastData: zipsStarterData,
			channelTitle: "Appcast",
			downloadsLink: URL(string: "https://he.ho.hum/myapps/downloads"),
			signatureGenerator: { _ in "Secured! jk"},
			downloadURLPrefix: #URL("https://he.ho.hum/updates/"))

		let jsonPairedData = try PKGAppcastGeneratorCore.generateAppcast(
			fromContentsOfDirectory: jsonPairedDirectory,
			previousAppcastData: starterData,
			channelTitle: "Appcast",
			downloadsLink: URL(string: "https://he.ho.hum/myapps/downloads"),
			signatureGenerator: { _ in "Secured! jk"},
			downloadURLPrefix: #URL("https://he.ho.hum/updates/"))

		let xmlDoc = try XMLDocument(data: jsonPairedData)
		Self.cleanXMLDates(in: xmlDoc)

		XCTAssertEqual(xmlDoc, zipsExpectation)
	}

	func testSortWithMatchingBuilds() throws {
		let enclosure = AppcastItem.Enclosure(
			url: #URL("https://he.ho.hum/updates/myapp.pkg"),
			length: 0,
			mimeType: "application/octet-stream")

		let now = Date.now

		let base = AppcastItem(
			title: "2.1.7",
			link: #URL("https://he.ho.hum/myapps/downloads"),
			version: "35",
			shortVersionString: "2.1.7",
			description: nil,
			publishedDate: now,
			enclosure: enclosure)

		let greaterShortVersion = AppcastItem(
			title: "2.1.8",
			link: #URL("https://he.ho.hum/myapps/downloads"),
			version: "35",
			shortVersionString: "2.1.8",
			description: nil,
			publishedDate: now,
			enclosure: enclosure)

		var channel = AppcastChannel(title: "foo", items: [base, greaterShortVersion])
		try channel.sortItems()
		XCTAssertEqual(channel.items, [greaterShortVersion, base])
		channel.items = [greaterShortVersion, base]
		try channel.sortItems()
		XCTAssertEqual(channel.items, [greaterShortVersion, base])

		let lowerBuild = AppcastItem(
			title: "2.1.7",
			link: #URL("https://he.ho.hum/myapps/downloads"),
			version: "31",
			shortVersionString: "2.1.7",
			description: nil,
			publishedDate: now,
			enclosure: enclosure)

		channel.items = [base, lowerBuild]
		try channel.sortItems()
		XCTAssertEqual(channel.items, [base, lowerBuild])
		channel.items = [lowerBuild, base]
		try channel.sortItems()
		XCTAssertEqual(channel.items, [base, lowerBuild])

		let moreShortVersionComponents = AppcastItem(
			title: "2.1.7.1",
			link: #URL("https://he.ho.hum/myapps/downloads"),
			version: "35",
			shortVersionString: "2.1.7.1",
			description: nil,
			publishedDate: now,
			enclosure: enclosure)

		channel.items = [moreShortVersionComponents, base]
		try channel.sortItems()
		XCTAssertEqual(channel.items, [moreShortVersionComponents, base])
		channel.items = [base, moreShortVersionComponents]
		try channel.sortItems()
		XCTAssertEqual(channel.items, [moreShortVersionComponents, base])

		let older = AppcastItem(
			title: "2.1.7",
			link: #URL("https://he.ho.hum/myapps/downloads"),
			version: "35",
			shortVersionString: "2.1.7",
			description: nil,
			publishedDate: .distantPast,
			enclosure: enclosure)

		channel.items = [older, base]
		try channel.sortItems()
		XCTAssertEqual(channel.items, [base, older])
		channel.items = [base, older]
		try channel.sortItems()
		XCTAssertEqual(channel.items, [base, older])
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
