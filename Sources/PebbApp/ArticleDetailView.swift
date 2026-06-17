import SwiftUI
import WebKit

struct ArticleDetailView: View {
    let article: NewsArticle
    @Environment(\.dismiss) private var dismiss

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
                        .font(.system(size: 15))
                        .foregroundColor(Color(hex: "C4C0E0"))
                        .lineSpacing(6)
                        .padding(.horizontal, 14)
                        .padding(.top, 16)
                }
                if let sources = article.sources, !sources.isEmpty {
                    sourcesSection(sources)
                }
            }
        }
        .background(Color(hex: "0B0A12"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color(hex: "0B0A12"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    @ViewBuilder
    private var heroImage: some View {
        if !article.image_url.isEmpty {
            AsyncImage(url: URL(string: article.image_url)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color(hex: "2D1515"))
                        .frame(height: 240)
                        .overlay(ProgressView().tint(Color(hex: "7C6FCD")))
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 240)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color(hex: "2D1515"))
                        .frame(height: 240)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(Color(hex: "6E6A8A"))
                        )
                @unknown default:
                    Rectangle()
                        .fill(Color(hex: "2D1515"))
                        .frame(height: 240)
                }
            }
        }
    }

    private var articleHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text(article.category)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(hex: "F87171"))
                    .textCase(.uppercase)
                Text("·")
                    .foregroundColor(Color(hex: "6E6A8A"))
                Text(article.source)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: "6E6A8A"))
            }
            .padding(.top, 16)

            Text(article.title)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(hex: "EDEBF7"))
                .lineSpacing(2)

            Text(article.summary)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "A09CBA"))
                .lineSpacing(4)

            Text(article.published_at)
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "6E6A8A"))
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 16)
    }

    private func sourcesSection(_ sources: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .overlay(Color(hex: "FFFFFF").opacity(0.07))
            Text("Sources")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color(hex: "6E6A8A"))
                .textCase(.uppercase)
            ForEach(sources, id: \.self) { source in
                HStack(spacing: 6) {
                    Text("→")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "F87171"))
                    Text(source)
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "A09CBA"))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 20)
    }
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
        body {
            font-family: -apple-system, system-ui, sans-serif;
            font-size: 15px;
            line-height: 1.7;
            color: #C4C0E0;
            background: transparent;
            margin: 0;
            padding: 0;
        }
        p { margin-bottom: 1em; }
        .pull-quote {
            font-size: 18px;
            font-weight: 700;
            color: #F87171;
            border-top: 2px solid #F87171;
            border-bottom: 2px solid #F87171;
            padding: 12px 0;
            margin: 20px 0;
            line-height: 1.4;
        }
        strong { color: #EDEBF7; }
        a { color: #7C6FCD; }
        </style>
        </head>
        <body>\(html)</body>
        </html>
        """
    }
}
