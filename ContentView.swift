//
//  CheatSheetViews.swift
//  Snippy — Master-Detail Popover Views, Native Markdown Renderer & Modal Form
//
//  Implements:
//  1. Two-Panel Master-Detail split layout inside MenuBarExtra popover
//  2. Left Panel: Header bar, search bar, category pills, command list, and bottom Add (+) bar
//  3. Right Panel: Rich Markdown viewer with syntax-highlighted code blocks,
//     one-click code copy buttons, vertical scrolling, and explicit Close (X) button
//  4. Inline/Sheet Add & Edit Command modal form
//

import SwiftUI

// MARK: - Root Popover View (Two-Panel Master-Detail)

struct CheatSheetPopoverView: View {
    @ObservedObject var viewModel: CheatSheetViewModel

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                // LEFT PANEL: Searchable Titles & Tags List
                SidebarPanelView(viewModel: viewModel)
                    .frame(width: 250)
                    .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))

                Divider()

                // RIGHT PANEL: Markdown Detail View with Close (X) button
                DetailPanelView(viewModel: viewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(nsColor: .textBackgroundColor).opacity(0.35))
            }

            // Modal overlay for Adding / Editing Commands
            if viewModel.isPresentingAddModal {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture {
                        viewModel.isPresentingAddModal = false
                    }

                CommandFormModalView(
                    viewModel: viewModel,
                    existingEntry: viewModel.editingCommand
                )
                .frame(width: 480, height: 410)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(nsColor: .windowBackgroundColor))
                        .shadow(color: .black.opacity(0.35), radius: 20, y: 8)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
            if viewModel.isPresentingAbout {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .onTapGesture { viewModel.isPresentingAbout = false }

                AboutModalView(onClose: { viewModel.isPresentingAbout = false })
                    .frame(width: 340)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color(nsColor: .windowBackgroundColor))
                            .shadow(color: .black.opacity(0.35), radius: 20, y: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
                    )
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.15), value: viewModel.isPresentingAddModal)
        .animation(.easeOut(duration: 0.15), value: viewModel.isPresentingAbout)
    }
}

// MARK: - Left Panel (Searchable Command List + Bottom Add Button)

struct SidebarPanelView: View {
    @ObservedObject var viewModel: CheatSheetViewModel

    var body: some View {
        VStack(spacing: 0) {
            // App Branding Header
            HStack(spacing: 6) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.accentColor)
                Text("Snippy")
                    .font(.system(size: 13.5, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)
            .padding(.bottom, 4)

            // Search Input Bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 12, weight: .medium))

                TextField("Search commands or #tags...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12.5))

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
            .padding(.horizontal, 10)
            .padding(.top, 4)
            .padding(.bottom, 8)

            // Category Filter Strip
            if !viewModel.categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        CategoryPill(
                            title: "All",
                            isSelected: viewModel.selectedCategory == nil
                        ) {
                            viewModel.selectedCategory = nil
                        }

                        ForEach(viewModel.categories, id: \.self) { category in
                            CategoryPill(
                                title: category,
                                isSelected: viewModel.selectedCategory == category
                            ) {
                                viewModel.selectedCategory = (viewModel.selectedCategory == category) ? nil : category
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
                }
            }

            Divider()

            // Command Titles & Tags List
            if viewModel.filteredCommands.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 22))
                        .foregroundStyle(.tertiary)
                    Text("No matching commands")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(viewModel.filteredCommands) { entry in
                            CommandRowView(
                                entry: entry,
                                isSelected: viewModel.selectedCommandID == entry.id
                            )
                            .onTapGesture {
                                viewModel.selectedCommandID = entry.id
                            }
                            .contextMenu {
                                Button("Edit Entry...") {
                                    viewModel.presentEditCommandModal(for: entry)
                                }
                                Divider()
                                Button("Delete Entry", role: .destructive) {
                                    viewModel.deleteCommand(entry)
                                }
                            }
                        }
                    }
                    .padding(8)
                }
            }

            Divider()

            // Bottom Action Bar with Add (+) Button
            HStack {
                Button {
                    viewModel.presentNewCommandModal()
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Add Command")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
                .help("Add a new command cheat sheet entry (⌘N)")
                .keyboardShortcut("n", modifiers: [.command])

                Spacer()

                Text("\(viewModel.filteredCommands.count) items")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)

                Menu {
                    Button("About Snippy") {
                        viewModel.isPresentingAbout = true
                    }
                    Divider()
                    Button("Quit Snippy") {
                        NSApplication.shared.terminate(nil)
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .menuStyle(.borderlessButton)
                .frame(width: 22)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }
}

private struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.07))
                )
                .foregroundStyle(isSelected ? Color.white : Color.primary.opacity(0.8))
        }
        .buttonStyle(.plain)
    }
}

private struct CommandRowView: View {
    let entry: CommandEntry
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(entry.title)
                    .font(.system(size: 12.5, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)

                Spacer(minLength: 4)

                Text(entry.category)
                    .font(.system(size: 9.5, weight: .semibold))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.white.opacity(0.22) : Color.accentColor.opacity(0.14))
                    )
                    .foregroundStyle(isSelected ? .white : Color.accentColor)
            }

            if !entry.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(entry.tags.prefix(4), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(isSelected ? .white.opacity(0.85) : .secondary)
                    }
                }
                .lineLimit(1)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Right Panel (Markdown Detail View + Explicit Close X Button)

struct DetailPanelView: View {
    @ObservedObject var viewModel: CheatSheetViewModel

    var body: some View {
        if let entry = viewModel.selectedCommand {
            VStack(spacing: 0) {
                // Top Header Bar with Snippy Tag, Title, Category, Edit, Copy, and Close (X)
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Image(systemName: "terminal.fill")
                                    .font(.system(size: 9))
                                Text("Snippy")
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.primary.opacity(0.08)))
                            .foregroundStyle(.secondary)

                            Text(entry.title)
                                .font(.system(size: 15, weight: .bold))
                                .lineLimit(1)

                            Text(entry.category)
                                .font(.system(size: 10.5, weight: .semibold))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                                .foregroundStyle(Color.accentColor)
                        }

                        if !entry.tags.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(entry.tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }

                    Spacer()

                    if let badge = viewModel.copiedBadgeText {
                        Text(badge)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.green.opacity(0.14)))
                            .transition(.opacity)
                    }

                    // Edit Command Button
                    Button {
                        viewModel.presentEditCommandModal(for: entry)
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 12.5, weight: .medium))
                            .padding(5)
                            .background(Circle().fill(Color.primary.opacity(0.07)))
                    }
                    .buttonStyle(.plain)
                    .help("Edit this command entry")

                    // Explicit Close (X) Button: resets detail view (Option-click closes popover)
                    Button {
                        let optionPressed = NSEvent.modifierFlags.contains(.option)
                        viewModel.closeDetailOrDismissPopover(dismissWindow: optionPressed)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundStyle(.secondary)
                            .padding(6)
                            .background(Circle().fill(Color.primary.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .help("Close command view (Hold ⌥ Option to dismiss popover)")
                    .keyboardShortcut(.cancelAction)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(Color(nsColor: .windowBackgroundColor).opacity(0.85))

                Divider()

                // Scrollable Rich Markdown Body
                ScrollView(.vertical, showsIndicators: true) {
                    MarkdownDocumentView(
                        markdown: entry.markdownContent,
                        onCopyCode: { code in
                            viewModel.copyToClipboard(code, label: "Code Copied!")
                        }
                    )
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } else {
            // Empty / Reset State with Snippy Branding
            VStack(spacing: 12) {
                Spacer()

                Image(systemName: "terminal")
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.tertiary)

                Text("Snippy")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)

                Text("Select a command from the sidebar or create a new one.")
                    .font(.system(size: 12.5, weight: .regular))
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button("New Command") {
                        viewModel.presentNewCommandModal()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)

                    Button("Close Popover") {
                        viewModel.closeDetailOrDismissPopover(dismissWindow: true)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.top, 4)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Native Zero-Dependency Markdown Renderer & Syntax Highlighter

struct MarkdownDocumentView: View {
    let markdown: String
    let onCopyCode: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(parseBlocks(from: markdown).enumerated()), id: \.offset) { _, block in
                switch block {
                case .heading(let level, let text):
                    renderInlineMarkdown(text)
                        .font(.system(
                            size: level == 1 ? 16 : (level == 2 ? 14 : 12.5),
                            weight: .bold
                        ))
                        .foregroundStyle(.primary)
                        .padding(.top, level == 1 ? 2 : 4)

                case .paragraph(let text):
                    renderInlineMarkdown(text)
                        .font(.system(size: 12.5))
                        .foregroundStyle(.primary.opacity(0.9))
                        .lineSpacing(3)

                case .bulletItem(let text):
                    HStack(alignment: .firstTextBaseline, spacing: 7) {
                        Text("•")
                            .font(.system(size: 12.5, weight: .bold))
                            .foregroundStyle(Color.accentColor)
                        renderInlineMarkdown(text)
                            .font(.system(size: 12.5))
                            .foregroundStyle(.primary.opacity(0.9))
                            .lineSpacing(2)
                    }
                    .padding(.leading, 4)

                case .blockquote(let text):
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 1.5)
                            .fill(Color.accentColor.opacity(0.7))
                            .frame(width: 3)
                        renderInlineMarkdown(text)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 3)

                case .codeBlock(let language, let code):
                    SyntaxHighlightedCodeBlock(
                        language: language,
                        code: code,
                        onCopy: { onCopyCode(code) }
                    )
                }
            }
        }
        .textSelection(.enabled)
    }

    private func renderInlineMarkdown(_ raw: String) -> Text {
        if let attributed = try? AttributedString(
            markdown: raw,
            options: AttributedString.MarkdownParsingOptions(
                interpretedSyntax: .inlineOnlyPreservingWhitespace
            )
        ) {
            return Text(attributed)
        }
        return Text(raw)
    }

    private enum MarkdownBlock {
        case heading(level: Int, text: String)
        case paragraph(text: String)
        case bulletItem(text: String)
        case blockquote(text: String)
        case codeBlock(language: String, code: String)
    }

    private func parseBlocks(from input: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = input.components(separatedBy: .newlines)

        var isInsideCodeBlock = false
        var currentCodeLang = ""
        var currentCodeLines: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                if isInsideCodeBlock {
                    blocks.append(
                        .codeBlock(
                            language: currentCodeLang,
                            code: currentCodeLines.joined(separator: "\n")
                        )
                    )
                    currentCodeLines.removeAll()
                    currentCodeLang = ""
                    isInsideCodeBlock = false
                } else {
                    isInsideCodeBlock = true
                    currentCodeLang = String(trimmed.dropFirst(3)).trimmingCharacters(in: .whitespaces)
                }
                continue
            }

            if isInsideCodeBlock {
                currentCodeLines.append(line)
                continue
            }

            if trimmed.isEmpty {
                continue
            } else if trimmed.hasPrefix("### ") {
                blocks.append(.heading(level: 3, text: String(trimmed.dropFirst(4))))
            } else if trimmed.hasPrefix("## ") {
                blocks.append(.heading(level: 2, text: String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("# ") {
                blocks.append(.heading(level: 1, text: String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                blocks.append(.bulletItem(text: String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("> ") {
                blocks.append(.blockquote(text: String(trimmed.dropFirst(2))))
            } else {
                blocks.append(.paragraph(text: trimmed))
            }
        }

        if isInsideCodeBlock && !currentCodeLines.isEmpty {
            blocks.append(
                .codeBlock(
                    language: currentCodeLang,
                    code: currentCodeLines.joined(separator: "\n")
                )
            )
        }

        return blocks
    }
}

private struct SyntaxHighlightedCodeBlock: View {
    let language: String
    let code: String
    let onCopy: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(language.isEmpty ? "shell" : language.lowercased())
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)

                Spacer()

                Button(action: onCopy) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                        Text("Copy")
                            .font(.system(size: 10.5, weight: .medium))
                    }
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.primary.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
                .help("Copy code snippet to clipboard")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.primary.opacity(0.06))

            Divider()

            ScrollView(.horizontal, showsIndicators: false) {
                Text(highlightSyntax(code))
                    .font(.system(size: 12, design: .monospaced))
                    .lineSpacing(3.5)
                    .padding(10)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .underPageBackgroundColor).opacity(0.65))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
        )
    }

    private func highlightSyntax(_ source: String) -> AttributedString {
        var result = AttributedString()
        let lines = source.components(separatedBy: "\n")

        for (index, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            var lineAttr = AttributedString(line)

            if trimmed.hasPrefix("#") || trimmed.hasPrefix("//") {
                lineAttr.foregroundColor = .secondary
            } else {
                lineAttr = tokenizeCommandLine(line)
            }

            result.append(lineAttr)
            if index < lines.count - 1 {
                result.append(AttributedString("\n"))
            }
        }
        return result
    }

    private func tokenizeCommandLine(_ line: String) -> AttributedString {
        var output = AttributedString()
        let tokens = line.split(separator: " ", omittingEmptySubsequences: false)
        let commonCommands: Set<String> = [
            "git", "docker", "lsof", "kill", "killall", "sudo", "defaults",
            "dscacheutil", "brew", "kubectl", "ssh", "scp", "curl", "tar",
            "find", "grep", "awk", "sed", "chmod", "chown", "tmux", "npm", "swift"
        ]

        for (idx, tokenSub) in tokens.enumerated() {
            let token = String(tokenSub)
            var attr = AttributedString(token)

            if commonCommands.contains(token) {
                attr.foregroundColor = .cyan
                attr.inlinePresentationIntent = .stronglyEmphasized
            } else if token.hasPrefix("-") {
                attr.foregroundColor = .orange
            } else if token.hasPrefix("$") || token.hasPrefix("<") {
                attr.foregroundColor = .purple
            } else if token.hasPrefix("\"") || token.hasPrefix("'") {
                attr.foregroundColor = .green
            }

            output.append(attr)
            if idx < tokens.count - 1 {
                output.append(AttributedString(" "))
            }
        }
        return output
    }
}

// MARK: - Modal Form to Add / Edit Command Entries

struct CommandFormModalView: View {
    @ObservedObject var viewModel: CheatSheetViewModel
    let existingEntry: CommandEntry?

    @State private var title: String = ""
    @State private var category: String = ""
    @State private var tagsInput: String = ""
    @State private var markdownContent: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(existingEntry == nil ? "Add New Command" : "Edit Command")
                    .font(.system(size: 14, weight: .bold))

                Spacer()

                Button {
                    viewModel.isPresentingAddModal = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 15))
                }
                .buttonStyle(.plain)
            }

            Divider()

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Title")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("e.g., Port Process Lookup", text: $title)
                        .textFieldStyle(.roundedBorder)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Category")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    TextField("e.g., Network, Git, Docker", text: $category)
                        .textFieldStyle(.roundedBorder)
                }
                .frame(width: 155)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Tags (comma-separated)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                TextField("e.g., lsof, port, tcp, kill", text: $tagsInput)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Markdown Content")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Insert ```bash Block") {
                        markdownContent += "\n```bash\n# command here\n```\n"
                    }
                    .buttonStyle(.link)
                    .font(.system(size: 11))
                }

                TextEditor(text: $markdownContent)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(nsColor: .textBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Color.primary.opacity(0.14), lineWidth: 1)
                    )
            }

            HStack {
                Spacer()
                Button("Cancel") {
                    viewModel.isPresentingAddModal = false
                }
                .keyboardShortcut(.cancelAction)

                Button(existingEntry == nil ? "Save Command" : "Update Command") {
                    viewModel.saveCommand(
                        id: existingEntry?.id,
                        title: title,
                        category: category,
                        rawTags: tagsInput,
                        markdownContent: markdownContent
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    markdownContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(16)
        .onAppear {
            if let existing = existingEntry {
                title = existing.title
                category = existing.category
                tagsInput = existing.tagsString
                markdownContent = existing.markdownContent
            } else {
                markdownContent = """
                ### Description
                Brief summary of what this command does.

                ```bash
                # Enter your command here
                echo "Hello, macOS!"
                ```
                """
            }
        }
    }
}

// MARK: - About Modal

struct AboutModalView: View {
    let onClose: () -> Void

    // TODO: replace with your real links
    private let githubURL = URL(string: "https://github.com/Hivis5/Snippy")!
    private let portfolioURL = URL(string: "https://hiteshvishal.netlify.app/")!

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 15))
                }
                .buttonStyle(.plain)
            }

            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)

            Text("Snippy")
                .font(.system(size: 18, weight: .bold))

            Text("Menu bar command cheat sheet")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            Divider()

            HStack(spacing: 12) {
                Link(destination: githubURL) {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                }

                Text("|")
                    .foregroundStyle(.tertiary)

                Link(destination: portfolioURL) {
                    Label("Portfolio", systemImage: "globe")
                }
            }
            .font(.system(size: 12.5, weight: .medium))

            Divider()

            Text("Made by Hitesh Vishal | A Local First dev initiative")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(16)
    }
}
