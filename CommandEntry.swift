//
//  CommandEntry.swift
//  QuickCmd — Model & Local Persistence Store
//

import Foundation

// MARK: - Domain Model

/// Represents a single cheat-sheet command entry.
struct CommandEntry: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var category: String
    var tags: [String]
    var markdownContent: String
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        tags: [String],
        markdownContent: String,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.tags = tags
        self.markdownContent = markdownContent
        self.updatedAt = updatedAt
    }

    /// Formatted comma-separated tags string for editing in forms.
    var tagsString: String {
        tags.joined(separator: ", ")
    }

    /// Parses a comma-separated string of tags into normalized tokens.
    static func parseTags(_ raw: String) -> [String] {
        raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

// MARK: - Local JSON Persistence Service

/// Thread-safe, lightweight file-based persistence service with zero background CPU usage.
/// Reads once on startup and writes atomically on background I/O queue only when mutated.
final class CommandStorageService {
    static let shared = CommandStorageService()

    private let fileURL: URL
    private let ioQueue = DispatchQueue(label: "com.quickcmd.storage.io", qos: .utility)

    init(customDirectory: URL? = nil) {
        if let customDirectory {
            self.fileURL = customDirectory.appendingPathComponent("commands.json")
        } else {
            let appSupport = FileManager.default.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first!
            let directory = appSupport.appendingPathComponent("QuickCmd", isDirectory: true)
            try? FileManager.default.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            self.fileURL = directory.appendingPathComponent("commands.json")
        }
    }

    /// Synchronously loads commands on initial launch; falls back to curated starter data.
    func loadCommands() -> [CommandEntry] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            let defaults = Self.seedCommands
            saveCommands(defaults)
            return defaults
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([CommandEntry].self, from: data)
        } catch {
            return Self.seedCommands
        }
    }

    /// Asynchronously persists commands using atomic write to prevent data corruption.
    func saveCommands(_ commands: [CommandEntry]) {
        ioQueue.async { [fileURL] in
            do {
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(commands)
                try data.write(to: fileURL, options: [.atomic])
            } catch {
                #if DEBUG
                print("[QuickCmd] Failed to save commands: \(error.localizedDescription)")
                #endif
            }
        }
    }
}

// MARK: - Default Seed Data

extension CommandStorageService {
    static let seedCommands: [CommandEntry] = [
        CommandEntry(
            title: "How to Add a New Command",
            category: "QuickCmd Guide",
            tags: ["guide", "template", "syntax", "markdown"],
            markdownContent: """
            # Creating a Command Entry

            Use this format to add custom shell shortcuts, workflows, or scripts to your collection.

            ---

            ### 1. Entry Structure
            Each entry consists of four primary properties:
            - **`title`**: A concise, searchable action name (e.g., *Docker Prune Unused Images*).
            - **`category`**: Grouping category displayed in the sidebar filter (e.g., *Docker*, *Git*, *Network*).
            - **`tags`**: Lowercase keywords used to match search queries.
            - **`markdownContent`**: Multi-line Markdown explaining the command and usage.

            ---

            ### 2. Markdown Snippet Template
            Enclose executable shell snippets inside triple backticks (```bash):

            ```bash
            # Step 1: Dry run or inspect target state
            command --check <ARGUMENT>

            # Step 2: Execute command
            command --flag --option "value"
            ```

            ---

            ### 3. Syntax Rules & Conventions
            - **Placeholders**: Wrap user-supplied inputs in `<UPPERCASE>` brackets (e.g., `<PORT>`, `<BRANCH_NAME>`).
            - **Flags**: Include bullet points below code blocks to explain non-obvious flags.
            - **Escaping**: You can write backticks directly inside multiline strings without backslashes.
            """
        )
    ]
}
