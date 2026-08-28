//
//  InputMethodsSettingsView.swift
//  KeyType
//
//  Per-input-method KeyType enablement. The list mirrors the selectable keyboard input sources
//  currently enabled in macOS; methods absent from the saved deny-list are on by default.
//

import SwiftUI

struct InputMethodsSettingsView: View {
    @Bindable var inputMethods: InputMethodController

    var body: some View {
        Form {
            Section("Active input methods") {
                Text("Choose which macOS input methods KeyType can run alongside. New input methods are enabled by default.")
                    .font(.callout)
                    .foregroundStyle(.secondary)

                if inputMethods.activeInputMethods.isEmpty {
                    Text("No active input methods detected.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                ForEach(inputMethods.activeInputMethods) { inputMethod in
                    Toggle(isOn: Binding(
                        get: { inputMethods.isEnabled(inputMethod) },
                        set: { inputMethods.setEnabled($0, for: inputMethod) }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(inputMethod.name)
                                if inputMethod.identifier == inputMethods.selectedInputMethodIdentifier {
                                    Text("Current")
                                        .font(.caption2.weight(.medium))
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(.quaternary, in: Capsule())
                                }
                            }
                            Text(inputMethod.identifier)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .textSelection(.enabled)
                        }
                    }
                }

                Button("Refresh input methods") {
                    inputMethods.refresh()
                }
                .font(.footnote)
            }
        }
        .formStyle(.grouped)
        .onAppear { inputMethods.refresh() }
    }
}
