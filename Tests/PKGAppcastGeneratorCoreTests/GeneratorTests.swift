import XCTest
import PKGAppcastGeneratorCore
import PizzaMacros
import ZIPFoundation
import SwiftPizzaSnips

class GeneratorTests: XCTestCase {
	func testGenerateAppcastJSONFromScratch() throws {
		let directory = Bundle.module.url(forResource: "JSON", withExtension: nil, subdirectory: "TestResources")!
		let jsonExpectationURL = Bundle.module.url(forResource: "expectedJSONResult", withExtension: "xml", subdirectory: "TestResources")!
		let jsonExpectation = try XMLDocument(contentsOf: jsonExpectationURL)

		let data = try PKGAppcastGeneratorCore.generateAppcast(
			fromContentsOfDirectory: directory,
			previousAppcastData: nil, 
			maximumVersionsToRetain: nil,
			rssChannelTitle: "Appcast",
			appcastChannelName: nil,
			downloadsLink: nil,
			signatureGenerator: { _ in "Secured! jk"},
			downloadURLPrefix: #URL("https://he.ho.hum/updates/"))

		let xmlDoc = try XMLDocument(data: data)
		Self.cleanXMLDates(in: xmlDoc)

		XCTAssertEqual(xmlDoc, jsonExpectation)
		if xmlDoc != jsonExpectation {
			try ComparingForTests.compareFilesInFinder(
				withExpectation: .data(jsonExpectation.xmlData(options: .nodePrettyPrint), fileExtension: "xml"),
				andActualResult: .data(xmlDoc.xmlData(options: .nodePrettyPrint), fileExtension: "xml"),
				contextualInfo: #function)
		}
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
			maximumVersionsToRetain: nil,
			rssChannelTitle: "Appcast",
			appcastChannelName: nil,
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
			maximumVersionsToRetain: nil,
			rssChannelTitle: "Appcast",
			appcastChannelName: nil,
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
			maximumVersionsToRetain: nil,
			rssChannelTitle: "Appcast",
			appcastChannelName: nil,
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
			maximumVersionsToRetain: nil,
			rssChannelTitle: "Appcast",
			appcastChannelName: nil,
			downloadsLink: URL(string: "https://he.ho.hum/myapps/downloads"),
			signatureGenerator: { _ in "Secured! jk"},
			downloadURLPrefix: #URL("https://he.ho.hum/updates/"))

		let jsonPairedData = try PKGAppcastGeneratorCore.generateAppcast(
			fromContentsOfDirectory: jsonPairedDirectory,
			previousAppcastData: starterData,
			maximumVersionsToRetain: nil,
			rssChannelTitle: "Appcast",
			appcastChannelName: nil,
			downloadsLink: URL(string: "https://he.ho.hum/myapps/downloads"),
			signatureGenerator: { _ in "Secured! jk"},
			downloadURLPrefix: #URL("https://he.ho.hum/updates/"))

		let xmlDoc = try XMLDocument(data: jsonPairedData)
		Self.cleanXMLDates(in: xmlDoc)

		XCTAssertEqual(xmlDoc, zipsExpectation)
	}

	func testGenerateAppcastWithCull() throws {
		let directory = Bundle.module.url(forResource: "ZipsAppend", withExtension: nil, subdirectory: "TestResources")!
		let zipsStarterURL = Bundle.module.url(forResource: "expectedZipsResult", withExtension: "xml", subdirectory: "TestResources")!
		let zipsStarterData = try Data(contentsOf: zipsStarterURL)
		let zipsExpectationURL = Bundle.module.url(forResource: "expectedZipsAppendWithCullResult", withExtension: "xml", subdirectory: "TestResources")!
		let zipsExpectation = try XMLDocument(contentsOf: zipsExpectationURL)

		let data = try PKGAppcastGeneratorCore.generateAppcast(
			fromContentsOfDirectory: directory,
			previousAppcastData: zipsStarterData,
			maximumVersionsToRetain: 2,
			rssChannelTitle: "Appcast",
			appcastChannelName: nil,
			downloadsLink: URL(string: "https://he.ho.hum/myapps/downloads"),
			signatureGenerator: { _ in "Secured! jk"},
			downloadURLPrefix: #URL("https://he.ho.hum/updates/"))

		let xmlDoc = try XMLDocument(data: data)
		Self.cleanXMLDates(in: xmlDoc)

		XCTAssertEqual(xmlDoc, zipsExpectation)
	}

	func testGenerateAppcastZipViaAppendWithNewChannel() throws {
		let directory = Bundle.module.url(forResource: "ZipsAppend", withExtension: nil, subdirectory: "TestResources")!
		let zipsStarterURL = Bundle.module.url(forResource: "starterZipsWithBeta", withExtension: "xml", subdirectory: "TestResources")!
		let zipsStarterData = try Data(contentsOf: zipsStarterURL)
		let zipsExpectationURL = Bundle.module.url(forResource: "expectedZipsWithBetaAppendNewBeta", withExtension: "xml", subdirectory: "TestResources")!
		let zipsExpectation = try XMLDocument(contentsOf: zipsExpectationURL)

		let data = try PKGAppcastGeneratorCore.generateAppcast(
			fromContentsOfDirectory: directory,
			previousAppcastData: zipsStarterData,
			maximumVersionsToRetain: nil,
			rssChannelTitle: "Appcast",
			appcastChannelName: "beta",
			downloadsLink: URL(string: "https://he.ho.hum/myapps/downloads"),
			signatureGenerator: { _ in "Secured! jk"},
			downloadURLPrefix: #URL("https://he.ho.hum/updates/"))

		let xmlDoc = try XMLDocument(data: data)
		Self.cleanXMLDates(in: xmlDoc)

		XCTAssertEqual(xmlDoc, zipsExpectation)
		if xmlDoc != zipsExpectation {
			try ComparingForTests.compareFilesInFinder(
				withExpectation: .url(zipsExpectationURL),
				andActualResult: .data(xmlDoc.xmlData(options: .nodePrettyPrint), fileExtension: "xml"),
				contextualInfo: #function)
		}
	}

	func testGenerateAppcastZipWithBetaAppendNonBeta() throws {
		let directory = Bundle.module.url(forResource: "ZipsAppend", withExtension: nil, subdirectory: "TestResources")!
		let zipsStarterURL = Bundle.module.url(forResource: "starterZipsWithBeta", withExtension: "xml", subdirectory: "TestResources")!
		let zipsStarterData = try Data(contentsOf: zipsStarterURL)
		let zipsExpectationURL = Bundle.module.url(forResource: "expectedZipsWithBetaAppend", withExtension: "xml", subdirectory: "TestResources")!
		let zipsExpectation = try XMLDocument(contentsOf: zipsExpectationURL)

		let data = try PKGAppcastGeneratorCore.generateAppcast(
			fromContentsOfDirectory: directory,
			previousAppcastData: zipsStarterData,
			maximumVersionsToRetain: nil,
			rssChannelTitle: "Appcast",
			appcastChannelName: nil,
			downloadsLink: URL(string: "https://he.ho.hum/myapps/downloads"),
			signatureGenerator: { _ in "Secured! jk"},
			downloadURLPrefix: #URL("https://he.ho.hum/updates/"))

		let xmlDoc = try XMLDocument(data: data)
		Self.cleanXMLDates(in: xmlDoc)

		XCTAssertEqual(xmlDoc, zipsExpectation)
		if xmlDoc != zipsExpectation {
			try ComparingForTests.compareFilesInFinder(
				withExpectation: .url(zipsExpectationURL),
				andActualResult: .data(xmlDoc.xmlData(options: .nodePrettyPrint), fileExtension: "xml"),
				contextualInfo: #function)
		}
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
			channel: nil,
			version: "35",
			shortVersionString: "2.1.7",
			description: nil,
			publishedDate: now,
			enclosure: enclosure)

		let greaterShortVersion = AppcastItem(
			title: "2.1.8",
			link: #URL("https://he.ho.hum/myapps/downloads"),
			channel: nil,
			version: "35",
			shortVersionString: "2.1.8",
			description: nil,
			publishedDate: now,
			enclosure: enclosure)

		var channel = RSSAppcastChannel(title: "foo", items: [base, greaterShortVersion])
		try channel.sortItems()
		XCTAssertEqual(channel.items, [greaterShortVersion, base])
		channel.itemChannels[RSSAppcastChannel.defaultChannel] = [greaterShortVersion, base]
		try channel.sortItems()
		XCTAssertEqual(channel.items, [greaterShortVersion, base])

		let lowerBuild = AppcastItem(
			title: "2.1.7",
			link: #URL("https://he.ho.hum/myapps/downloads"),
			channel: nil,
			version: "31",
			shortVersionString: "2.1.7",
			description: nil,
			publishedDate: now,
			enclosure: enclosure)

		channel.itemChannels[RSSAppcastChannel.defaultChannel] = [base, lowerBuild]
		try channel.sortItems()
		XCTAssertEqual(channel.items, [base, lowerBuild])
		channel.itemChannels[RSSAppcastChannel.defaultChannel] = [lowerBuild, base]
		try channel.sortItems()
		XCTAssertEqual(channel.items, [base, lowerBuild])

		let moreShortVersionComponents = AppcastItem(
			title: "2.1.7.1",
			link: #URL("https://he.ho.hum/myapps/downloads"),
			channel: nil,
			version: "35",
			shortVersionString: "2.1.7.1",
			description: nil,
			publishedDate: now,
			enclosure: enclosure)

		channel.itemChannels[RSSAppcastChannel.defaultChannel] = [moreShortVersionComponents, base]
		try channel.sortItems()
		XCTAssertEqual(channel.items, [moreShortVersionComponents, base])
		channel.itemChannels[RSSAppcastChannel.defaultChannel] = [base, moreShortVersionComponents]
		try channel.sortItems()
		XCTAssertEqual(channel.items, [moreShortVersionComponents, base])

		let older = AppcastItem(
			title: "2.1.7",
			link: #URL("https://he.ho.hum/myapps/downloads"),
			channel: nil,
			version: "35",
			shortVersionString: "2.1.7",
			description: nil,
			publishedDate: .distantPast,
			enclosure: enclosure)

		channel.itemChannels[RSSAppcastChannel.defaultChannel] = [older, base]
		try channel.sortItems()
		XCTAssertEqual(channel.items, [base, older])
		channel.itemChannels[RSSAppcastChannel.defaultChannel] = [base, older]
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
