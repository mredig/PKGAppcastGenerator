import Foundation
import ZIPFoundation

public extension Entry {
	var pathURL: URL? {
		URLComponents(string: "zip:///\(path)")?.url
	}

	var componentCount: Int {
		pathURL?.pathComponents.count ??
		path.split(separator: "/").count + 1
	}
}
