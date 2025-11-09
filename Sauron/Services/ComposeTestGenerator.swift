import Foundation

enum ComposeTestGenerator {
    struct Result {
        let created: [String] // relative paths created
    }

    static func generateTests(root: URL, components: [ComposeComponent]) -> Result {
        var created: [String] = []
        for comp in components where comp.hasPreview { // align with CLI behavior
            if let path = writeKotlinPreviewTest(root: root, comp: comp) {
                created.append(path)
            }
        }
        return Result(created: created)
    }

    private static func writeKotlinPreviewTest(root: URL, comp: ComposeComponent) -> String? {
        let compPath = comp.filePath.replacingOccurrences(of: "\\", with: "/")
        let moduleRel: String = {
            if let range = compPath.range(of: "/src/") {
                return String(compPath[..<range.lowerBound])
            }
            return ""
        }()

        let moduleAbs = root.appendingPathComponent(moduleRel)
        let pkg = kotlinPackage(from: root.appendingPathComponent(comp.filePath))
            ?? inferPackage(fromRelPath: compPath)
            ?? "screenshot.generated"

        let pkgDir = moduleAbs
            .appendingPathComponent("src")
            .appendingPathComponent("screenshotTest")
            .appendingPathComponent("kotlin")
            .appendingPathComponent(pkg.replacingOccurrences(of: ".", with: "/"))

        do { try FileManager.default.createDirectory(at: pkgDir, withIntermediateDirectories: true) } catch { return nil }

        let suffix: String = comp.name.hasSuffix("Preview") ? "ScreenshotTest" : "PreviewScreenshotTest"
        let baseName = comp.name + suffix
        let fileName = baseName + ".kt"
        let fileAbs = pkgDir.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: fileAbs.path) {
            return nil
        }

        let previewLine = comp.previewAnnotations.first ?? "@Preview"
        var content = ""
        content += "package \(pkg)\n\n"
        content += "import androidx.compose.runtime.Composable\n"
        content += "import androidx.compose.ui.tooling.preview.Preview\n"
        content += "import com.android.tools.screenshot.PreviewTest\n\n"
        content += "@PreviewTest\n"
        content += previewLine + "\n"
        content += "@Composable\n"
        content += "fun \(baseName)() {\n"
        content += "    // TODO: wrap with your app theme if needed\n"
        content += "    \(comp.name)()\n"
        content += "}\n"

        do {
            try content.write(to: fileAbs, atomically: true, encoding: .utf8)
        } catch {
            return nil
        }

        // return relative path from root
        let createdRel = fileAbs.path.replacingOccurrences(of: root.path + "/", with: "")
        return createdRel
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

