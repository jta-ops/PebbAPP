import SwiftUI
import WebKit
import UIKit

struct ArticleDetailView: View {
    let article: NewsArticle
    @Environment(\.dismiss) private var dismiss
    @StateObject private var bookmarks = BookmarksStore.shared
    @State private var scrollProgress: CGFloat = 0

    var catColor: Color { categoryColor(article.category) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                heroImage
                articleHeader
                if let html = article.content_html {
                    ArticleWebView(html: html, baseURL: "https://pebb.dev")
                        .frame(minHeight: 400)
                        .padding(.horizontal, 14)
                } else if let text = article.content_text {
                    Text(text)
                        .fixedSize(horizontal: false, vertical: true)
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "C4C0E0"))
                        .lineSpacing(6)
                        .padding(.horizontal, 14)
                        .padding(.top, 16)
                }
                if let sources = article.sources, !sources.isEmpty {
                    sourcesSection(sources)
                }
            }
            .background(
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ScrollOffsetKey.self,
                        value: -geo.frame(in: .named("articleScroll")).minY / max(1, geo.size.height - UIScreen.main.bounds.height)
                    )
                }
            )
        }
        .coordinateSpace(name: "articleScroll")
        .onPreferenceChange(ScrollOffsetKey.self) { v in
            scrollProgress = min(1, max(0, v))
        }
        .background(Color(hex: "0B0A12"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "0B0A12"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        bookmarks.toggle(article)
                    } label: {
                        Image(systemName: bookmarks.isBookmarked(article) ? "bookmark.fill" : "bookmark")
                            .foregroundStyle(Color(hex: "9B8FE8"))
                    }
                    if let url = URL(string: article.source_url) {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up").foregroundStyle(Color(hex: "9B8FE8"))
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            GeometryReader { geo in
                Rectangle()
                    .fill(LinearGradient(colors: [catColor, Color(hex: "9B8FE8")], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * scrollProgress, height: 3)
            }
            .frame(height: 3)
        }
    }

    @ViewBuilder
    private var heroImage: some View {
        if !article.image_url.isEmpty {
            AsyncImage(url: URL(string: article.image_url)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color(hex: "2D1515"))
                        .frame(height: 260)
                        .overlay(ProgressView().tint(Color(hex: "7C6FCD")))
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 260)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .clear,
                                    Color(hex: "0B0A12").opacity(0.5),
                                    Color(hex: "0B0A12")
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                case .failure:
                    Rectangle()
                        .fill(Color(hex: "2D1515"))
                        .frame(height: 260)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundStyle(Color(hex: "6E6A8A"))
                        )
                @unknown default:
                    Rectangle().fill(Color(hex: "2D1515")).frame(height: 260)
                }
            }
        }
    }

    private var articleHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(article.category)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(catColor)
                    .textCase(.uppercase)
                Text("·")
                    .foregroundStyle(Color(hex: "6E6A8A"))
                Text(article.source)
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "6E6A8A"))
                Spacer()
                Text(readingTime(for: article))
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "6E6A8A"))
            }
            .padding(.top, 16)

            Text(article.title)
                .fixedSize(horizontal: false, vertical: true)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Color(hex: "EDEBF7"))
                .lineSpacing(2)
                .tracking(-0.3)

            Text(article.summary)
                .fixedSize(horizontal: false, vertical: true)
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "A09CBA"))
                .lineSpacing(4)

            Text(article.published_at)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "6E6A8A"))
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 16)
    }

    private func sourcesSection(_ sources: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider().overlay(Color(hex: "FFFFFF").opacity(0.07))
            Text("Sources")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color(hex: "6E6A8A"))
                .textCase(.uppercase)
            ForEach(sources, id: \.self) { source in
                HStack(spacing: 6) {
                    Text("→")
                        .font(.system(size: 11))
                        .foregroundStyle(catColor)
                    Text(source)
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "A09CBA"))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 20)
    }
}

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

struct ArticleWebView: UIViewRepresentable {
    let html: String
    let baseURL: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = false
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.loadHTMLString(wrappedHTML, baseURL: URL(string: baseURL))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    private var wrappedHTML: String {
        """
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style>
        body { font-family:-apple-system,system-ui,sans-serif; font-size:15px; line-height:1.7; color:#C4C0E0; background:transparent; margin:0; padding:0; }
        p { margin-bottom:1em; }
        .pull-quote { font-size:18px; font-weight:700; color:#F87171; border-top:2px solid #F87171; border-bottom:2px solid #F87171; padding:12px 0; margin:20px 0; line-height:1.4; }
        strong { color:#EDEBF7; }
        a { color:#7C6FCD; }
        </style>
        </head>
        <body>\(html)</body>
        </html>
        """
    }
}
