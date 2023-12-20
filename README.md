# PKGAppcastGenerator

Creates [Sparkle](https://sparkle-project.org/documentation/) appcast files using zip, dmg, mpkg, or pkg update files (unlike [`generate_appcast`](#why-does-this-exist-when-theres-generate_appcast-included-in-sparkle)). Like `generate_appcast`, it supports pulling data directly from Info.plist files for `zip` files, but the remaining supported files require a companion `json` file with the same basename, matching the following structure:

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

### General notes about usage:

* While it used to just append duplicate entries if you ran it with the same data, outputting to the same appcast several times, it now forgoes adding duplicates with the same download link!
* It now works with both companion JSON files, but also supports .zip archives with embedded .app bundles (and pulls data from Info.plist! - so no JSON companion is required)
* While the models support a more comprehensive solution for all the properties that can be added to the xml output, much of it has been omitted for now. Support for providing input for these features in the output xml would be great contributions, if anyone feels up to it. (My intention, in regards to this, is to refactor the logic to instead glob all the archive types, simply requiring json for formats that it can't automatically pull data from, but supporting json as supplementary data for the remaining.)
	* releaseNotesLink
	* fullReleaseNotesLink
	* description
	* maximumSystemVersion
	* minimumAutoUpdateVersion
	* ignoreSkippedUpgradesBelowVersion
	* criticalUpdate
	* phasedRolloutInterval

## Usage

```
USAGE: pkg-appcast-generator <directory> --existing-appcast-url <existing-appcast-url> [--existing-appcast-file <existing-appcast-file>] [--downloads-link <downloads-link>] --download-url-prefix <download-url-prefix> [--channel-title <channel-title>] [--output-path <output-path>] [--sign-update-path <sign-update-path>] [--sign-update-account <sign-update-account>] [--sign-update-key-file <sign-update-key-file>]

ARGUMENTS:
  <directory>             The directory with the latest update and information.

OPTIONS:
  -e, --existing-appcast-url <existing-appcast-url>
                          Download and append to this online app cast. Optional.
  --existing-appcast-file <existing-appcast-file>
                          Download and append to this offline app cast.
                          Optional.
  --downloads-link <downloads-link>
                          Backup URL that a user can go manually download the
                          updates. The json files include this already, but if
                          you have any non json archives as updates, this is a
                          required value.
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

### Why does this exist when there's `generate_appcast` included in Sparkle?

Three reasons now: 

1. `generate_appcast` only supports archives with .app bundles within. I had a need for automation with `.pkg` installers.
1. Maybe it was pebkac or [this](https://www.cnn.com/2010/TECH/mobile/06/25/iphone.problems.response/index.html), but despite saying that it's supposed to sign all entries with an EdDSA key, I was unable to get my .app containing zips to get signed in another project.
1. It seemed fun!
