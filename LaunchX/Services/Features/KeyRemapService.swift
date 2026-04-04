import Cocoa
import Carbon

class KeyRemapService {
    static let shared = KeyRemapService()

    // MARK: - HID Key Codes
    private let kHIDCapsLock: Int64 = 0x700000039  // 30064771129
    private let kHIDLeftControl: Int64 = 0x7000000E0  // 30064771296

    // MARK: - State
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var rightCommandPressed = false

    // MARK: - Settings
    private var batchUpdate = false

    var capsControlSwapEnabled = false {
        didSet {
            if !batchUpdate {
                applyCapsControlSwap()
            }
        }
    }

    var hyperKeyEnabled = false {
        didSet { if !batchUpdate { updateEventTap() } }
    }

    var quoteSwapEnabled = false {
        didSet { if !batchUpdate { updateEventTap() } }
    }

    // MARK: - Accessibility Permission

    var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    var isEventTapActive: Bool {
        eventTap != nil && CGEvent.tapIsEnabled(tap: eventTap!)
    }

    private init() {}

    // MARK: - Batch Update

    func applySettings(capsSwap: Bool, hyper: Bool, quote: Bool) {
        batchUpdate = true
        capsControlSwapEnabled = capsSwap
        hyperKeyEnabled = hyper
        quoteSwapEnabled = quote
        batchUpdate = false
        // Apply Caps↔Ctrl via hidutil+defaults
        applyCapsControlSwap()
        // Start/stop CGEventTap for Hyper+Quote
        updateEventTap()
    }

    // MARK: - Caps ↔ Control Swap (hidutil + defaults)

    private func applyCapsControlSwap() {
        let keys = enumerateKeyboardMappingKeys()

        if capsControlSwapEnabled {
            // Write Caps↔LeftCtrl bidirectional swap
            let mappingArgs = [
                "{ HIDKeyboardModifierMappingDst = \(kHIDLeftControl); HIDKeyboardModifierMappingSrc = \(kHIDCapsLock); }",
                "{ HIDKeyboardModifierMappingDst = \(kHIDCapsLock); HIDKeyboardModifierMappingSrc = \(kHIDLeftControl); }",
            ]

            for key in keys {
                let args = ["-currentHost", "write", "-g", key, "-array"] + mappingArgs
                _ = runProcess("/usr/bin/defaults", arguments: args)
            }

            // Apply immediately via hidutil
            let json = "{\"UserKeyMapping\":[{\"HIDKeyboardModifierMappingSrc\":\(kHIDCapsLock),\"HIDKeyboardModifierMappingDst\":\(kHIDLeftControl)},{\"HIDKeyboardModifierMappingSrc\":\(kHIDLeftControl),\"HIDKeyboardModifierMappingDst\":\(kHIDCapsLock)}]}"
            let result = runProcess("/usr/bin/hidutil", arguments: ["property", "--set", json])
            print("KeyRemapService: Caps↔Ctrl enabled, hidutil: \(result)")
        } else {
            // Clear all keyboard mappings
            for key in keys {
                let args = ["-currentHost", "write", "-g", key, "-array"]
                _ = runProcess("/usr/bin/defaults", arguments: args)
            }

            // Clear hidutil immediately
            let result = runProcess("/usr/bin/hidutil", arguments: ["property", "--set", "{\"UserKeyMapping\":[]}"])
            print("KeyRemapService: Caps↔Ctrl disabled, hidutil: \(result)")
        }
    }

    /// Enumerate all keyboard modifier mapping keys from GlobalPreferences
    private func enumerateKeyboardMappingKeys() -> [String] {
        let output = runProcess("/usr/bin/defaults", arguments: ["-currentHost", "read", "-g"])
        var keys: [String] = []
        for line in output.components(separatedBy: "\n") {
            if line.contains("com.apple.keyboard.modifiermapping") {
                if let range = line.range(of: "\"com.apple.keyboard.modifiermapping.[^\"]+\"", options: .regularExpression) {
                    let key = String(line[range]).replacingOccurrences(of: "\"", with: "")
                    keys.append(key)
                }
            }
        }
        if keys.isEmpty {
            keys = ["com.apple.keyboard.modifiermapping.1452-833-0"]
        }
        return keys
    }

    /// Detect if Caps↔Ctrl swap is active in system GlobalPreferences
    func detectCapsControlSwap() -> Bool {
        let output = runProcess("/usr/bin/defaults", arguments: ["-currentHost", "read", "-g"])
        let entries = output.components(separatedBy: "}")
        for entry in entries {
            let hasCapsSrc = entry.contains("HIDKeyboardModifierMappingSrc = 30064771129")
            let hasCapsDst = entry.contains("HIDKeyboardModifierMappingDst = 30064771129")
            if hasCapsSrc && !hasCapsDst {
                return true
            }
        }
        return false
    }

    // MARK: - CGEventTap Lifecycle

    private func needsEventTap() -> Bool {
        (hyperKeyEnabled || quoteSwapEnabled) && hasAccessibilityPermission
    }

    private func updateEventTap() {
        if needsEventTap() {
            stopEventTap()
            startEventTap()
        } else {
            stopEventTap()
        }
    }

    private func startEventTap() {
        guard eventTap == nil else { return }
        guard hasAccessibilityPermission else { return }
        guard hyperKeyEnabled || quoteSwapEnabled else { return }

        let eventMask = CGEventMask(
            (1 << CGEventType.keyDown.rawValue)
                | (1 << CGEventType.flagsChanged.rawValue)
        )

        guard
            let tap = CGEvent.tapCreate(
                tap: .cghidEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: eventMask,
                callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                    guard let refcon = refcon else {
                        return Unmanaged.passUnretained(event)
                    }
                    let service = Unmanaged<KeyRemapService>.fromOpaque(refcon)
                        .takeUnretainedValue()
                    return service.handleEvent(proxy: proxy, type: type, event: event)
                },
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            )
        else {
            print("KeyRemapService: Failed to create CGEventTap")
            return
        }

        self.eventTap = tap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        print("KeyRemapService: CGEventTap started (hyper=\(hyperKeyEnabled), quote=\(quoteSwapEnabled))")
    }

    func stopEventTap() {
        guard let tap = eventTap else { return }
        CGEvent.tapEnable(tap: tap, enable: false)
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        rightCommandPressed = false
        print("KeyRemapService: CGEventTap stopped")
    }

    // MARK: - CGEventTap Callback

    private func handleEvent(
        proxy: CGEventTapProxy, type: CGEventType, event: CGEvent
    ) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            print("KeyRemapService: EventTap disabled, re-enabling")
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

        // Track Right Command state + inject Hyper modifiers into flagsChanged
        if hyperKeyEnabled, type == .flagsChanged, keyCode == 0x36 {
            updateHyperState(event: event)
            if rightCommandPressed {
                // Also tell the system that Ctrl+Shift+Option are pressed
                event.flags = event.flags.union([
                    .maskControl, .maskShift, .maskAlternate,
                ])
            }
        }

        // Inject Hyper modifiers into all keyDown events while Right Command held
        if hyperKeyEnabled, rightCommandPressed, type == .keyDown {
            event.flags = event.flags.union([
                .maskControl, .maskShift, .maskAlternate,
            ])
        }

        if quoteSwapEnabled, type == .keyDown, keyCode == 0x27 {
            handleQuoteSwap(event: event)
        }

        return Unmanaged.passUnretained(event)
    }

    // MARK: - Hyper Key (Right Command → Cmd+Ctrl+Shift+Option)

    private let NX_DEVICERCMDKEYMASK: UInt64 = 0x10

    private func updateHyperState(event: CGEvent) {
        let rawFlags = event.flags.rawValue
        let isRightDown = (rawFlags & NX_DEVICERCMDKEYMASK) != 0

        if isRightDown, !rightCommandPressed {
            rightCommandPressed = true
            print("KeyRemapService: Hyper ON (Right ⌘ held)")
        } else if !isRightDown, rightCommandPressed {
            rightCommandPressed = false
            print("KeyRemapService: Hyper OFF")
        }
    }

    // MARK: - Quote Swap (' ↔ ")

    private func handleQuoteSwap(event: CGEvent) {
        if event.flags.contains(.maskShift) {
            event.flags.subtract(.maskShift)
            print("KeyRemapService: Quote swap: \" → '")
        } else {
            event.flags.insert(.maskShift)
            print("KeyRemapService: Quote swap: ' → \"")
        }
    }

    // MARK: - Process Helper

    @discardableResult
    private func runProcess(_ executable: String, arguments: [String]) -> String {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            print("KeyRemapService: \(executable) failed: \(error)")
            return ""
        }
    }
}
