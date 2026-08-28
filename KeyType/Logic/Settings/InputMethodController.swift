//
//  InputMethodController.swift
//  KeyType
//
//  Tracks the selectable keyboard input sources enabled in macOS and the source currently selected
//  by the user. KeyType stores only a deny-list of stable TIS identifiers, so newly discovered input
//  methods default to enabled. Text Input Source Services is main-thread-only; this controller and
//  its provider therefore stay on the main actor.
//

import Carbon
import Foundation
import Observation

struct ActiveInputMethod: Equatable, Identifiable, Sendable {
    let identifier: String
    let name: String

    var id: String { identifier }
}

struct ActiveInputMethodSnapshot: Equatable, Sendable {
    var inputMethods: [ActiveInputMethod]
    var selectedIdentifier: String?
}

@MainActor
protocol ActiveInputMethodProviding {
    func snapshot() -> ActiveInputMethodSnapshot
}

/// Main-actor bridge to macOS Text Input Source Services. "Input methods" in Settings includes
/// selectable keyboard layouts and selectable modes as well as third-party input-method bundles,
/// matching the choices macOS exposes in its Input menu.
@MainActor
struct SystemActiveInputMethodProvider: ActiveInputMethodProviding {
    func snapshot() -> ActiveInputMethodSnapshot {
        let criteria = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource
        ] as CFDictionary
        let sourceList = TISCreateInputSourceList(criteria, false).takeRetainedValue() as NSArray

        var methodsByIdentifier: [String: ActiveInputMethod] = [:]
        for case let source as TISInputSource in sourceList {
            guard Self.boolProperty(source, key: kTISPropertyInputSourceIsEnabled),
                  Self.boolProperty(source, key: kTISPropertyInputSourceIsSelectCapable),
                  let method = Self.inputMethod(from: source) else {
                continue
            }
            methodsByIdentifier[method.identifier] = method
        }

        let currentSource = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        let currentMethod = Self.inputMethod(from: currentSource)
        if let currentMethod {
            // Defensive merge: the selected source should be in the enabled list, but retaining it
            // makes the current policy visible even if an input method reports incomplete metadata.
            methodsByIdentifier[currentMethod.identifier] = currentMethod
        }

        let methods = methodsByIdentifier.values.sorted { lhs, rhs in
            let nameComparison = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
            if nameComparison == .orderedSame {
                return lhs.identifier < rhs.identifier
            }
            return nameComparison == .orderedAscending
        }
        return ActiveInputMethodSnapshot(
            inputMethods: methods,
            selectedIdentifier: currentMethod?.identifier
        )
    }

    private static func inputMethod(from source: TISInputSource) -> ActiveInputMethod? {
        guard let identifier = stringProperty(source, key: kTISPropertyInputSourceID),
              !identifier.isEmpty else {
            return nil
        }
        let name = stringProperty(source, key: kTISPropertyLocalizedName) ?? identifier
        return ActiveInputMethod(identifier: identifier, name: name)
    }

    private static func stringProperty(_ source: TISInputSource, key: CFString) -> String? {
        guard let pointer = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
    }

    private static func boolProperty(_ source: TISInputSource, key: CFString) -> Bool {
        guard let pointer = TISGetInputSourceProperty(source, key) else { return false }
        let value = Unmanaged<CFBoolean>.fromOpaque(pointer).takeUnretainedValue()
        return CFBooleanGetValue(value)
    }
}

@MainActor
@Observable
final class InputMethodController {
    private let settings: SettingsStore
    @ObservationIgnored private let provider: any ActiveInputMethodProviding
    @ObservationIgnored private let notificationCenter: DistributedNotificationCenter
    @ObservationIgnored private var notificationTokens: [NSObjectProtocol] = []

    private(set) var activeInputMethods: [ActiveInputMethod]
    private(set) var selectedInputMethodIdentifier: String?

    /// Called after the selected input source changes, or when the user changes KeyType's policy for
    /// the selected source. AppDelegate uses this to clear stale UI and re-evaluate pipeline state.
    @ObservationIgnored var onSelectedInputMethodPolicyChange: (() -> Void)?

    init(
        settings: SettingsStore,
        provider: (any ActiveInputMethodProviding)? = nil,
        notificationCenter: DistributedNotificationCenter = .default()
    ) {
        self.settings = settings
        let resolvedProvider = provider ?? SystemActiveInputMethodProvider()
        self.provider = resolvedProvider
        self.notificationCenter = notificationCenter
        let snapshot = resolvedProvider.snapshot()
        self.activeInputMethods = snapshot.inputMethods
        self.selectedInputMethodIdentifier = snapshot.selectedIdentifier
    }

    var isKeyTypeEnabledForSelectedInputMethod: Bool {
        guard let selectedInputMethodIdentifier else { return true }
        return settings.isInputMethodEnabled(selectedInputMethodIdentifier)
    }

    func isEnabled(_ inputMethod: ActiveInputMethod) -> Bool {
        settings.isInputMethodEnabled(inputMethod.identifier)
    }

    func setEnabled(_ enabled: Bool, for inputMethod: ActiveInputMethod) {
        let changedSelectedPolicy = inputMethod.identifier == selectedInputMethodIdentifier
            && settings.isInputMethodEnabled(inputMethod.identifier) != enabled
        settings.setInputMethod(inputMethod.identifier, enabled: enabled)
        if changedSelectedPolicy {
            onSelectedInputMethodPolicyChange?()
        }
    }

    func start() {
        guard notificationTokens.isEmpty else { return }
        refresh(notifyIfSelectionChanged: false)

        let names = [
            Notification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String),
            Notification.Name(kTISNotifyEnabledKeyboardInputSourcesChanged as String),
        ]
        notificationTokens = names.map { name in
            notificationCenter.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refresh()
                }
            }
        }
    }

    func stop() {
        for token in notificationTokens {
            notificationCenter.removeObserver(token)
        }
        notificationTokens.removeAll()
    }

    func refresh() {
        refresh(notifyIfSelectionChanged: true)
    }

    private func refresh(notifyIfSelectionChanged: Bool) {
        let previousIdentifier = selectedInputMethodIdentifier
        let snapshot = provider.snapshot()
        activeInputMethods = snapshot.inputMethods
        selectedInputMethodIdentifier = snapshot.selectedIdentifier

        if notifyIfSelectionChanged, previousIdentifier != snapshot.selectedIdentifier {
            onSelectedInputMethodPolicyChange?()
        }
    }
}
