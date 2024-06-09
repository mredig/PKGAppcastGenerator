import SwiftUI

@available(macOS 14.0, *)
protocol MainSignatureCheckerViewdDelegate: AnyObject {
	func mainView(_ mainView: MainSignatureCheckerView, didEncounterError error: Error)
}

@available(macOS 14.0, *)
struct MainSignatureCheckerView: View {
	@State
	var viewModel: SignatureCheckerViewModel

	@State
	private var isShowingError = false
	@State
	private var error: LocalizedError?

	unowned let delegate: MainSignatureCheckerViewdDelegate

	var body: some View {
		Form {
			LabeledContent("File") {
				if let filename = viewModel.selectedFilename {
					Text(filename)
						.foregroundStyle(.primary)
				} else {
					Text("Open a file")
						.font(.system(size: 10))
						.foregroundStyle(.secondary)
						.italic()
				}
			}

			TextField("File Signature", text: $viewModel.base64Signature)
			Text("with base64 encoding")
				.font(.system(size: 10))
				.foregroundStyle(.secondary)

			TextField("Public Key", text: $viewModel.base64PublicKey)
			Text("with base64 encoding")
				.font(.system(size: 10))
				.foregroundStyle(.secondary)

			LabeledContent("Validation Status") {
				VStack {
					let color = {
						switch viewModel.validationStatus {
						case .unknown:
							Color.yellow
						case .invalid:
							Color.red
						case .valid:
							Color.green
						}
					}()
					Image(systemName: "circle.fill")
						.foregroundStyle(color)

					Text(viewModel.validationStatus.rawValue)
						.font(.system(size: 10))
						.foregroundStyle(.secondary)
				}

				Spacer()
				
				Button(
					action: {
						Task {
							do {
								try await viewModel.verifySigatureIsValid()
							} catch {
								delegate.mainView(self, didEncounterError: error)
							}
						}
					},
					label: {
						Text("Validate")
					})
			}

			if viewModel.isProcessing {
				ProgressView()

			}
		}
		.padding()
	}
}
