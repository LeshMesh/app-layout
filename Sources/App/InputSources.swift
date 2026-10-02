import AppKit
import Carbon

struct InputSourceOption: Identifiable, Equatable {
    let id: String
    let name: String
}

/// Text Input Source Services is the only API that changes the layout.
@MainActor
final class InputSourceService {
    private func selectableSources() -> [TISInputSource] {
        let filter = [
            kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as Any,
            kTISPropertyInputSourceIsSelectCapable as String: true,
            kTISPropertyInputSourceIsEnabled as String: true
        ] as CFDictionary
        guard let result = TISCreateInputSourceList(filter, false) else { return [] }
        return result.takeRetainedValue() as! [TISInputSource]
    }

    func options() -> [InputSourceOption] {
        selectableSources().compactMap { source in
            guard let id = stringProperty(source, kTISPropertyInputSourceID),
                  let name = stringProperty(source, kTISPropertyLocalizedName) else { return nil }
            return InputSourceOption(id: id, name: name)
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func currentID() -> String? {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else { return nil }
        return stringProperty(source, kTISPropertyInputSourceID)
    }

    enum SelectionResult { case selected, unavailable, failed(OSStatus) }

    func select(id: String) -> SelectionResult {
        guard let source = selectableSources().first(where: {
            stringProperty($0, kTISPropertyInputSourceID) == id
        }) else { return .unavailable }
        let result = TISSelectInputSource(source)
        return result == noErr ? .selected : .failed(result)
    }

    private func stringProperty(_ source: TISInputSource, _ key: CFString) -> String? {
        guard let pointer = TISGetInputSourceProperty(source, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
    }
}
