import SwiftUI

/// Renders a markdown string with support for headers, bold/italic, inline code,
/// fenced code blocks, bullet/numbered lists and links — tuned for chat bubbles.
struct MarkdownText: View {
    let text: String
    var textColor: Color = Color(hex: "EDEBF7")

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
        }
    }

    // MARK: - Block model
    private enum Block {
        case heading(String, level: Int)
        case code(String)
        case bullet([String])
        case numbered([String])
        case paragraph(String)
    }

    @ViewBuilder
    private func blockView(_ block: Block) -> some View {
        switch block {
        case .heading(let t, let level):
            inline(t)
                .font(.system(size: level == 1 ? 19 : level == 2 ? 17 : 15, weight: .bold))
                .foregroundStyle(textColor)
        case .code(let code):
            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Color(hex: "D4CFFF"))
                    .padding(10)
            }
            .background(Color.black.opacity(0.28))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.08), lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        case .bullet(let items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•").foregroundStyle(Color(hex: "9B8FE8")).font(.system(size: 14.5, weight: .bold))
                        inline(item).font(.system(size: 14.5)).foregroundStyle(textColor)
                    }
                }
            }
        case .numbered(let items):
            VStack(alignment: .leading, spacing: 4) {
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(i + 1).").foregroundStyle(Color(hex: "9B8FE8")).font(.system(size: 14.5, weight: .semibold))
                        inline(item).font(.system(size: 14.5)).foregroundStyle(textColor)
                    }
                }
            }
        case .paragraph(let t):
            inline(t).font(.system(size: 14.5)).foregroundStyle(textColor)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// Inline markdown (bold, italic, code, links) via AttributedString.
    private func inline(_ s: String) -> Text {
        if let attr = try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            return Text(attr)
        }
        return Text(s)
    }

    // MARK: - Parsing
    private var blocks: [Block] {
        var result: [Block] = []
        let lines = text.components(separatedBy: "\n")
        var i = 0
        var pendingBullets: [String] = []
        var pendingNumbers: [String] = []

        func flushLists() {
            if !pendingBullets.isEmpty { result.append(.bullet(pendingBullets)); pendingBullets = [] }
            if !pendingNumbers.isEmpty { result.append(.numbered(pendingNumbers)); pendingNumbers = [] }
        }

        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.hasPrefix("```") {
                flushLists()
                var code: [String] = []
                i += 1
                while i < lines.count && !lines[i].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    code.append(lines[i]); i += 1
                }
                result.append(.code(code.joined(separator: "\n")))
                i += 1
                continue
            }
            if trimmed.hasPrefix("### ") { flushLists(); result.append(.heading(String(trimmed.dropFirst(4)), level: 3)) }
            else if trimmed.hasPrefix("## ") { flushLists(); result.append(.heading(String(trimmed.dropFirst(3)), level: 2)) }
            else if trimmed.hasPrefix("# ") { flushLists(); result.append(.heading(String(trimmed.dropFirst(2)), level: 1)) }
            else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                if !pendingNumbers.isEmpty { flushLists() }
                pendingBullets.append(String(trimmed.dropFirst(2)))
            }
            else if let r = trimmed.range(of: #"^\d+\.\s"#, options: .regularExpression) {
                if !pendingBullets.isEmpty { flushLists() }
                pendingNumbers.append(String(trimmed[r.upperBound...]))
            }
            else if trimmed.isEmpty { flushLists() }
            else { flushLists(); result.append(.paragraph(trimmed)) }
            i += 1
        }
        flushLists()
        return result
    }
}
