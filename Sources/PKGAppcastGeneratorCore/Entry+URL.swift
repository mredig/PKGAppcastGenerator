import Foundation
import ZIPFoundation

public extension Entry {
	var pathURL: URL? {
		URL(string: "zip:///\(path)")
	}

	var componentCount: Int {
		pathURL?.pathComponents.count ??
		path.split(separator: "/").count + 1
	}
}
