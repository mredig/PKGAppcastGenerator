import Foundation
import ArgumentParser
import PKGAppcastGeneratorCore

@main
struct PKGAppcastGenerator: ParsableCommand {
    mutating func run() throws {
//        print("Hello, world!")
		try PKGAppcastGeneratorCore.asdf()
    }
}
