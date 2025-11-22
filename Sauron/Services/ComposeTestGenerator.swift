import Foundation

enum ComposeTestGenerator {
    struct Result {
        let created: [String] // relative paths created
    }

    private struct ThemeInfo {
        let packageName: String
        let functionName: String
    }

    private static var themeCache: [String: ThemeInfo?] = [:]

    static func generateTests(root: URL, components: [ComposeComponent]) -> Result {
        var created: [String] = []
        
        for comp in components where comp.hasPreview {
            if let path = writeKotlinPreviewTest(root: root, comp: comp) {
                created.append(path)
            }
        }

        return Result(created: created)
    }

    private static func writeKotlinPreviewTest(root: URL, comp: ComposeComponent) -> String? {
        let compPath = comp.filePath.replacingOccurrences(of: "\\", with: "/")

        // Determine module root: handle both project-root and module-root selections
        let moduleAbs: URL = {
            if let range = compPath.range(of: "/src/") {
                let prefix = String(compPath[..<range.lowerBound])
                if prefix.isEmpty {
                    return root
                } else {
                    return root.appendingPathComponent(prefix)
                }
            } else {
                return root
            }
        }()

        let sourceFile = root.appendingPathComponent(comp.filePath)
        let pkg = kotlinPackage(from: sourceFile)
            ?? inferPackage(fromRelPath: compPath)
            ?? "screenshot.generated"

        let pkgDir = moduleAbs
            .appendingPathComponent("src")
            .appendingPathComponent("screenshotTest")
            .appendingPathComponent("kotlin")
            .appendingPathComponent(pkg.replacingOccurrences(of: ".", with: "/"))

        do {
            try FileManager.default.createDirectory(at: pkgDir, withIntermediateDirectories: true)
        } catch {
            return nil
        }

        let suffix: String = comp.name.hasSuffix("Preview") ? "ScreenshotTest" : "PreviewScreenshotTest"
        let baseName = comp.name + suffix
        let fileName = baseName + ".kt"
        let fileAbs = pkgDir.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: fileAbs.path) {
            return nil
        }

        let previewLine = comp.previewAnnotations.first ?? "@Preview"
        let themeInfo = themeInfoCache(for: moduleAbs)

        var lines: [String] = []
        lines.append("package \(pkg)")
        lines.append("")
        lines.append("import androidx.compose.runtime.Composable")
        lines.append("import androidx.compose.ui.tooling.preview.Preview")
        lines.append("import com.android.tools.screenshot.PreviewTest")
        if let themeInfo = themeInfo {
            lines.append("import \(themeInfo.packageName).\(themeInfo.functionName)")
        }
        lines.append("")
        lines.append("@PreviewTest")
        lines.append(previewLine)
        lines.append("@Composable")
        lines.append("fun \(baseName)() {")
        if let themeInfo = themeInfo {
            lines.append("    \(themeInfo.functionName) {")
            lines.append("        \(comp.name)()")
            lines.append("    }")
        } else {
            lines.append("    // TODO: wrap with your app theme if needed")
            lines.append("    \(comp.name)()")
        }
        lines.append("}")
        let content = lines.joined(separator: "\n")

        do {
            try content.write(to: fileAbs, atomically: true, encoding: .utf8)
        } catch {
            return nil
        }

        let createdRel = fileAbs.path.replacingOccurrences(of: root.path + "/", with: "")
        return createdRel
    }

    private static func themeInfoCache(for moduleAbs: URL) -> ThemeInfo? {
        let key = moduleAbs.path
        if let cached = themeCache[key] { return cached }
        let resolved = detectTheme(in: moduleAbs)
        themeCache[key] = resolved
        return resolved
    }

    private static func detectTheme(in moduleAbs: URL) -> ThemeInfo? {
        let fm = FileManager.default
        let searchDirs = ["src/main/kotlin", "src/main/java", "src/commonMain/kotlin"]
        for candidate in searchDirs {
            let baseDir = moduleAbs.appendingPathComponent(candidate)
            guard fm.fileExists(atPath: baseDir.path) else { continue }
            guard let enumerator = fm.enumerator(at: baseDir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
            for case let file as URL in enumerator {
                if file.hasDirectoryPath { continue }
                if file.pathExtension != "kt" { continue }
                guard let text = try? String(contentsOf: file) else { continue }
                guard let themeName = findThemeFunction(in: text) else { continue }
                let relPath = relativePath(of: file, to: moduleAbs)
                guard let pkg = kotlinPackage(from: file) ?? inferPackage(fromRelPath: relPath) else { continue }
                return ThemeInfo(packageName: pkg, functionName: themeName)
            }
        }
        return nil
    }

    private static func relativePath(of file: URL, to moduleAbs: URL) -> String {
        let prefix = moduleAbs.path.hasSuffix("/") ? moduleAbs.path : moduleAbs.path + "/"
        if file.path.hasPrefix(prefix) {
            return String(file.path.dropFirst(prefix.count))
        }
        return file.lastPathComponent
    }

    private static func findThemeFunction(in text: String) -> String? {
        var sawComposable = false
        for rawLine in text.split(whereSeparator: { $0.isNewline }) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("@Composable") {
                sawComposable = true
                continue
            }
            if sawComposable && line.hasPrefix("fun ") {
                if let name = extractFunctionName(from: line), name.hasSuffix("Theme") {
                    return name
                }
            }
            if line.isEmpty {
                sawComposable = false
            }
        }
        return nil
    }

    private static func extractFunctionName(from line: String) -> String? {
        guard let range = line.range(of: "fun ") else { return nil }
        let afterFun = line[range.upperBound...]
        var name = ""
        for ch in afterFun {
            if ch.isLetter || ch.isNumber || ch == "_" {
                name.append(ch)
            } else {
                break
            }
        }
        return name.isEmpty ? nil : name
    }

    private static func kotlinPackage(from file: URL) -> String? {
        guard let data = try? Data(contentsOf: file), let text = String(data: data, encoding: .utf8) else { return nil }
        for line in text.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("package ") {
                return String(trimmed.dropFirst("package ".count)).trimmingCharacters(in: .whitespaces)
            }
        }
        return nil
    }

    private static func inferPackage(fromRelPath relPath: String) -> String? {
        let candidates = ["/src/main/java/", "/src/main/kotlin/", "/src/commonMain/kotlin/"]
        for key in candidates {
            if let range = relPath.range(of: key) {
                let rest = String(relPath[range.upperBound...])
                let dir = (rest as NSString).deletingLastPathComponent
                if dir.isEmpty || dir == "." { return nil }
                return dir.replacingOccurrences(of: "/", with: ".")
            }
        }
        return nil
    }
}
