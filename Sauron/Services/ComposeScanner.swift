import Foundation

struct ComposeComponent {
    let name: String
    let filePath: String   // relative to project root
    let line: Int
    let hasPreview: Bool
    let previewAnnotations: [String]
}

enum ComposeScanner {
    static func detectComponents(at root: URL) -> [ComposeComponent] {
        var components: [ComposeComponent] = []
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            return []
        }

        let ignoredDirs: Set<String> = [".git", ".gradle", ".idea", "build", "node_modules", "vendor", "Pods"]

        for case let url as URL in enumerator {
            let last = url.lastPathComponent
            if ignoredDirs.contains(last) {
                enumerator.skipDescendants()
                continue
            }
            if url.pathExtension != "kt" { continue }

            let relPath = url.path.replacingOccurrences(of: root.path + "/", with: "")
            if let fileComponents = parseComposeFile(absPath: url, relPath: relPath) {
                components.append(contentsOf: fileComponents)
            }
        }
        return components
    }

    private static func parseComposeFile(absPath: URL, relPath: String) -> [ComposeComponent]? {
        guard let fileHandle = try? FileHandle(forReadingFrom: absPath) else { return nil }
        defer { try? fileHandle.close() }
        guard let data = try? fileHandle.readToEnd(), let text = String(data: data, encoding: .utf8) else { return nil }

        var result: [ComposeComponent] = []
        var pendingAnnotations: [String] = []
        var lineNumber = 0

        text.enumerateLines { line, _ in
            lineNumber += 1
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                pendingAnnotations.removeAll()
                return
            }

            let containsComposable = trimmed.contains("@Composable")
            let containsPreview = trimmed.contains("@Preview")

            if trimmed.hasPrefix("@") {
                pendingAnnotations.append(trimmed)
            } else if containsComposable || containsPreview {
                pendingAnnotations.append(trimmed)
            }

            if let name = functionName(in: trimmed) {
                if !containsComposable && !pendingAnnotations.contains(where: { $0.hasPrefix("@Composable") }) {
                    pendingAnnotations.removeAll()
                    return
                }
                let previews = pendingAnnotations.filter { $0.hasPrefix("@Preview") }
                result.append(ComposeComponent(
                    name: name,
                    filePath: relPath.replacingOccurrences(of: "\\", with: "/"),
                    line: lineNumber,
                    hasPreview: !previews.isEmpty,
                    previewAnnotations: previews
                ))
                pendingAnnotations.removeAll()
            } else if !trimmed.hasPrefix("@") {
                pendingAnnotations.removeAll()
            }
        }
        return result
    }

    private static func functionName(in line: String) -> String? {
        // simple regex-like parse for: fun Name(
        guard let range = line.range(of: "fun ") else { return nil }
        let afterFun = line[range.upperBound...]
        // collect identifier chars until non-identifier
        var name = ""
        for ch in afterFun {
            if (ch >= "A" && ch <= "Z") || (ch >= "a" && ch <= "z") || (ch >= "0" && ch <= "9") || ch == "_" {
                name.append(ch)
            } else {
                break
            }
        }
        return name.isEmpty ? nil : name
    }

    // Compose Screenshot plugin detection for tip
    static func hasComposeScreenshotPlugin(at root: URL) -> Bool {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
            return false
        }
        let pluginPatterns: [String] = [
            "com.android.compose.screenshot",
            "libs.plugins.screenshot"
        ]
        for case let url as URL in enumerator {
            if url.hasDirectoryPath { continue }
            let path = url.path
            if !(path.hasSuffix(".toml") || path.hasSuffix(".gradle") || path.hasSuffix(".gradle.kts")) {
                continue
            }
            if let content = try? String(contentsOf: url) {
                if pluginPatterns.contains(where: { content.contains($0) }) {
                    return true
                }
            }
        }
        return false
    }
}
