//
//  QuickCmdApp.swift
//  QuickCmd — Ultra-Lightweight macOS Menu Bar Command Cheat Sheet
//
//  Target: macOS 13.0+ (Ventura / Sonoma / Sequoia)
//  Architecture: Clean MVVM, Zero External Dependencies
//
//  ===========================================================================
//  INFO.PLIST CONFIGURATION (Menu-Bar-Only / Accessory Mode)
//  ===========================================================================
//  To run purely in the macOS menu bar with NO Dock icon and NO main menu bar:
//  1. In Xcode, select your Project -> Target -> "Info" tab.
//  2. Add Key: "Application is agent (UIElement)" (Raw key: `LSUIElement`)
//  3. Set Type: Boolean | Value: YES (`true`)
//
//  Raw Info.plist XML snippet:
//  <key>LSUIElement</key>
//  <true/>
//  ===========================================================================

import SwiftUI
import AppKit
import Carbon.HIToolbox

@main
struct QuickCmdApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = CheatSheetViewModel()

    var body: some Scene {
        // Native macOS 13+ MenuBarExtra with `.window` style renders a crisp
        // floating popover anchored to the top-right status bar icon.
        MenuBarExtra("Snippy", systemImage: "terminal.fill") {
            CheatSheetPopoverView(viewModel: viewModel)
                .frame(width: 720, height: 480)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Ensures strict accessory activation policy (no Dock icon, no app switcher entry)
/// even if `LSUIElement` was omitted from Info.plist during rapid prototyping.
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var hotKey: GlobalHotKey?   // ← ADD

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // ← ADD
        hotKey = GlobalHotKey(
            keyCode: UInt32(kVK_ANSI_W),
            modifiers: UInt32(optionKey)
        ) {
            MenuBarToggler.toggle()
        }
    }
}
