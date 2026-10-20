import SwiftUI
import AppKit
import SwiftUI
import Combine
import Foundation

@MainActor
final class CheatSheetViewModel: ObservableObject {
    // MARK: - Published State

    @Published private(set) var commands: [CommandEntry] = []
    @Published var searchText: String = ""
    @Published var selectedCategory: String? = nil
    @Published var selectedCommandID: UUID? = nil
    @Published var isPresentingAddModal: Bool = false
    @Published var editingCommand: CommandEntry? = nil
    @Published private(set) var copiedBadgeText: String? = nil
    @Published var isPresentingAbout: Bool = false

    // MARK: - Dependencies

    private let storage: CommandStorageService

    // MARK: - Initialization

    init(storage: CommandStorageService = .shared) {
        self.storage = storage
        let loaded = storage.loadCommands()
        self.commands = loaded
        self.selectedCommandID = loaded.first?.id
    }

    // MARK: - Computed Properties

    /// Distinct sorted categories across all stored commands.
    var categories: [String] {
        let unique = Set(commands.map { $0.category }.filter { !$0.isEmpty })
        return unique.sorted()
    }

    /// Commands matching both the active category filter and the search query.
    var filteredCommands: [CommandEntry] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return commands.filter { entry in
            if let category = selectedCategory, entry.category != category {
                return false
            }
            guard !query.isEmpty else { return true }

            let matchesTitle = entry.title.lowercased().contains(query)
            let matchesCategory = entry.category.lowercased().contains(query)
            let matchesTags = entry.tags.contains { $0.lowercased().contains(query) }
            let matchesBody = entry.markdownContent.lowercased().contains(query)

            return matchesTitle || matchesCategory || matchesTags || matchesBody
        }
    }

    /// Currently selected command entry for the right-hand detail panel.
    var selectedCommand: CommandEntry? {
        guard let selectedCommandID else { return nil }
        return commands.first { $0.id == selectedCommandID }
    }

    // MARK: - User Intents / Actions

    /// Adds a newly created command or updates an existing command, then persists to disk.
    func saveCommand(
        id: UUID? = nil,
        title: String,
        category: String,
        rawTags: String,
        markdownContent: String
    ) {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsedTags = CommandEntry.parseTags(rawTags)

        guard !cleanTitle.isEmpty, !markdownContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        if let existingID = id, let index = commands.firstIndex(where: { $0.id == existingID }) {
            commands[index].title = cleanTitle
            commands[index].category = cleanCategory.isEmpty ? "General" : cleanCategory
            commands[index].tags = parsedTags
            commands[index].markdownContent = markdownContent
            commands[index].updatedAt = Date()
            selectedCommandID = existingID
        } else {
            let newEntry = CommandEntry(
                title: cleanTitle,
                category: cleanCategory.isEmpty ? "General" : cleanCategory,
                tags: parsedTags,
                markdownContent: markdownContent
            )
            commands.insert(newEntry, at: 0)
            selectedCommandID = newEntry.id
        }

        storage.saveCommands(commands)
        isPresentingAddModal = false
        editingCommand = nil
    }

    /// Deletes a command entry and updates selection gracefully.
    func deleteCommand(_ entry: CommandEntry) {
        commands.removeAll { $0.id == entry.id }
        if selectedCommandID == entry.id {
            selectedCommandID = filteredCommands.first?.id
        }
        storage.saveCommands(commands)
    }

    /// Opens the modal form configured to create a fresh entry.
    func presentNewCommandModal() {
        editingCommand = nil
        isPresentingAddModal = true
    }

    /// Opens the modal form pre-populated with an existing entry for editing.
    func presentEditCommandModal(for entry: CommandEntry) {
        editingCommand = entry
        isPresentingAddModal = true
    }

    /// Clears the current selection or closes the floating MenuBarExtra popover window.
    func closeDetailOrDismissPopover(dismissWindow: Bool = false) {
        if dismissWindow {
            NSApp.keyWindow?.close()
            NSApp.deactivate()
        } else {
            selectedCommandID = nil
        }
    }

    /// Copies a string to the macOS general pasteboard and triggers a transient status badge.
    func copyToClipboard(_ text: String, label: String = "Copied!") {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        copiedBadgeText = label
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if self.copiedBadgeText == label {
                self.copiedBadgeText = nil
            }
        }
    }
}
