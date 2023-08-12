#  PKGAppcastGenerator

Allows for creation of Sparkle appcast files with pkg distribution. Instead of relying on the embedded Info.plist like the official appcast generator in Sparkle, this instead just requires that you create a json file with the same filename (just using the json extension) matching the follow structure:

```swift
public struct JSONAppcastItem: Codable {
	public let title: String
	public let link: URL
	public let releaseNotesLink: URL?
	public let fullReleaseNotesLink: URL?
	public let version: String
	public let shortVersionString: String?
	public let description: String?
	public let minimumSystemVersion: String?
	public let maximumSystemVersion: String?
	public let minimumAutoUpdateVersion: String?
	public let ignoreSkippedUpgradesBelowVersion: String?
	
	/// This value would be `1.2.4` in `<sparkle:criticalUpdate sparkle:version="1.2.4"></sparkle:criticalUpdate>`
	public let criticalUpdate: String?
	public let phasedRolloutInterval: Int?
}
```

Note that it is designed to append the entire contents of the passed directory to any previous appcast you provide. If you get around this by running it fresh on the same files over and over, their publish dates will be overwritten each time.

## Usage

```
USAGE: pkg-appcast-generator <directory> --existing-appcast-url <existing-appcast-url> [--existing-appcast-file <existing-appcast-file>] --download-url-prefix <download-url-prefix> [--channel-title <channel-title>] [--output-path <output-path>] [--sign-update-path <sign-update-path>] [--sign-update-account <sign-update-account>] [--sign-update-key-file <sign-update-key-file>]

ARGUMENTS:
  <directory>             The directory with the latest update and information.

OPTIONS:
  -e, --existing-appcast-url <existing-appcast-url>
                          Download and append to this online app cast. Optional.
  --existing-appcast-file <existing-appcast-file>
                          Download and append to this offline app cast.
                          Optional.
  -d, --download-url-prefix <download-url-prefix>
                          The root url download prefix of the file(s). If a
                          given update will be available at
                          `https://foo.com/path/to/bar.zip`, this value would
                          need to be `https://foo.com/path/to/`
  -c, --channel-title <channel-title>
                          The title for the channel. Defaults to "App Changelog"
  -o, --output-path <output-path>
                          Where to save the output file. Defaults to
                          `./appcast.xml`.
  --sign-update-path <sign-update-path>
                          Path to Sparkle's `sign_update` executable
  --sign-update-account <sign-update-account>
                          Account value for Sparkle's `sign_update` executable
  --sign-update-key-file <sign-update-key-file>
                          Path to EdDSA file for `sign_update` executable
  -h, --help              Show help information.
```
