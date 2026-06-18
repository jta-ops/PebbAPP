import SwiftUI
import UIKit
import CoreSpotlight
import UniformTypeIdentifiers

func categoryColor(_ cat: String) -> Color {
    switch cat.lowercased() {
    case "tech", "technology", "ai": return Color(hex: "7C6FCD")
    case "world", "global", "international": return Color(hex: "F59E0B")
    case "business", "finance", "economy": return Color(hex: "10B981")
    case "science": return Color(hex: "06B6D4")
    case "health", "medical": return Color(hex: "F472B6")
    case "entertainment", "culture": return Color(hex: "A78BFA")
    case "politics": return Color(hex: "60A5FA")
    case "sports": return Color(hex: "FB923C")
    default: return Color(hex: "F87171")
    }
}

func readingTime(for article: NewsArticle) -> String {
    let text = article.content_text ?? article.summary
    let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    let mins = max(1, words / 200)
    return "\(mins) min read"
}

struct NewsTabView: View {
    @StateObject private var api = PebbAPI.shared
    @StateObject private var bookmarks = BookmarksStore.shared
    @State private var selectedArticle: NewsArticle?
    @State private var selectedCategory: String? = nil
    @State private var showBookmarks = false

    private var categories: [String] {
        var seen = Set<String>()
        var ordered: [String] = []
        for a in api.newsArticles {
            let c = a.category
            if !c.isEmpty && !seen.contains(c.lowercased()) {
                seen.insert(c.lowercased()); ordered.append(c)
            }
        }
        return ordered
    }

    private var filteredArticles: [NewsArticle] {
        guard let cat = selectedCategory else { return api.newsArticles }
        return api.newsArticles.filter { $0.category.lowercased() == cat.lowercased() }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topBar
                if !api.newsArticles.isEmpty { categoryBar }
                if api.isLoadingNews {
                    Spacer()
                    ProgressView().tint(Color(hex: "7C6FCD"))
                    Spacer()
                } else if api.newsArticles.isEmpty {
                    emptyState
                } else {
                    articlesList
                }
            }
            .background(Color(hex: "0B0A12"))
            .task {
                try? await api.loadNews()
                donateToSpotlight(api.newsArticles)
            }
            .refreshable {
                try? await api.loadNews()
                donateToSpotlight(api.newsArticles)
            }
            .navigationDestination(item: $selectedArticle) { ArticleDetailView(article: $0) }
            .sheet(isPresented: $showBookmarks) {
                BookmarksView(selectedArticle: $selectedArticle)
            }
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 9) {
                Image(systemName: "newspaper")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color(hex: "F87171"))
                    .frame(width: 30, height: 30)
                    .background(Color(hex: "2D1515"))
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                Text("Pebb News")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(Color(hex: "EDEBF7"))
            }
            Spacer()
            Button { showBookmarks = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(Color(hex: "9B8FE8"))
                        .frame(width: 38, height: 38)
                        .background(Color(hex: "1E1C30"))
                        .overlay(RoundedRectangle(cornerRadius: 11).stroke(Color.white.opacity(0.1), lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 11))
                    if !bookmarks.articles.isEmpty {
                        Text("\(bookmarks.articles.count)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color(hex: "7C6FCD"))
                            .clipShape(Circle())
                            .offset(x: 5, y: -5)
                    }
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .overlay(Divider().overlay(Color(hex: "FFFFFF").opacity(0.07)), alignment: .bottom)
    }

    private var categoryBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                categoryChip(title: "All", color: Color(hex: "9B8FE8"), active: selectedCategory == nil) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { selectedCategory = nil }
                }
                ForEach(categories, id: \.self) { cat in
                    categoryChip(title: cat, color: categoryColor(cat), active: selectedCategory?.lowercased() == cat.lowercased()) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedCategory = (selectedCategory?.lowercased() == cat.lowercased()) ? nil : cat
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(Color(hex: "0B0A12"))
    }

    private func categoryChip(title: String, color: Color, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            action()
        } label: {
            Text(title.capitalized)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(active ? .white : color)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(active ? AnyShapeStyle(color) : AnyShapeStyle(color.opacity(0.12)))
                .overlay(Capsule().stroke(color.opacity(active ? 0 : 0.4), lineWidth: 1))
                .clipShape(Capsule())
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "newspaper")
                .font(.system(size: 48))
                .foregroundStyle(Color(hex: "6E6A8A"))
            Text("No articles yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(hex: "EDEBF7"))
            Text("Daily news will appear here each morning.")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "6E6A8A"))
            Button("Refresh") { Task { try? await api.loadNews() } }
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "7C6FCD"))
            Spacer()
        }
    }

    private var articlesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(Array(filteredArticles.enumerated()), id: \.element.id) { index, article in
                    ArticleRow(article: article, index: index)
                        .onTapGesture { selectedArticle = article }
                        .contextMenu {
                            Button {
                                BookmarksStore.shared.toggle(article)
                            } label: {
                                Label(bookmarks.isBookmarked(article) ? "Remove bookmark" : "Bookmark",
                                      systemImage: bookmarks.isBookmarked(article) ? "bookmark.slash" : "bookmark")
                            }
                            if let src = article.source_url, let url = URL(string: src) {
                                ShareLink(item: url) { Label("Share", systemImage: "square.and.arrow.up") }
                            }
                        }
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.immediately)
    }
}

// MARK: - Spotlight donation
private func donateToSpotlight(_ articles: [NewsArticle]) {
    let items = articles.prefix(30).map { article -> CSSearchableItem in
        let attrs = CSSearchableItemAttributeSet(contentType: UTType.text)
        attrs.title = article.title
        attrs.contentDescription = article.summary
        attrs.keywords = [article.category, article.source, "pebb", "news"]
        return CSSearchableItem(
            uniqueIdentifier: "pebb.news.\(article.slug)",
            domainIdentifier: "dev.pebb.news",
            attributeSet: attrs
        )
    }
    CSSearchableIndex.default().indexSearchableItems(items) { _ in }
}

// MARK: - Bookmarks View
struct BookmarksView: View {
    @StateObject private var bookmarks = BookmarksStore.shared
    @Binding var selectedArticle: NewsArticle?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0B0A12").ignoresSafeArea()
                if bookmarks.articles.isEmpty {
                    VStack(spacing: 14) {
                        Image(systemName: "bookmark")
                            .font(.system(size: 44))
                            .foregroundStyle(Color(hex: "6E6A8A"))
                        Text("No bookmarks yet")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Color(hex: "EDEBF7"))
                        Text("Long-press any article to save it here for offline reading.")
                            .font(.system(size: 13))
                            .foregroundStyle(Color(hex: "6E6A8A"))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(bookmarks.articles.enumerated()), id: \.element.id) { index, article in
                                ArticleRow(article: article, index: index)
                                    .onTapGesture { dismiss(); selectedArticle = article }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            bookmarks.remove(article)
                                        } label: { Label("Remove", systemImage: "trash") }
                                    }
                                    .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("Saved")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.foregroundStyle(Color(hex: "9B8FE8"))
                }
            }
            .toolbarBackground(Color(hex: "0B0A12"), for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

struct ArticleRow: View {
    let article: NewsArticle
    let index: Int
    @State private var appear = false
    @StateObject private var bookmarks = BookmarksStore.shared

    var catColor: Color { categoryColor(article.category) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            articleImage
                .overlay(alignment: .topTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        bookmarks.toggle(article)
                    } label: {
                        Image(systemName: bookmarks.isBookmarked(article) ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(bookmarks.isBookmarked(article) ? Color(hex: "9B8FE8") : .white)
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                            .clipShape(Circle())
                            .padding(10)
                    }
                }
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(article.category.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(catColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .glassPill(tint: catColor)
                    Text(article.source)
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "6E6A8A"))
                    Spacer()
                    Text(readingTime(for: article))
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "6E6A8A"))
                }
                Text(article.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color(hex: "EDEBF7"))
                    .lineLimit(3)
                    .tracking(-0.3)
                Text(article.summary)
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: "A09CBA"))
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
        }
        .liquidGlass(cornerRadius: 14, tint: catColor, tintOpacity: 0.03)
        .overlay(
            // Left accent bar by category
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(catColor.opacity(0.8))
                    .frame(width: 3)
                    .padding(.vertical, 12)
                Spacer()
            }
        )
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 18)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.055)) {
                appear = true
            }
        }
    }

    @ViewBuilder
    private var articleImage: some View {
        if !article.absoluteImageURL.isEmpty {
            AsyncImage(url: URL(string: article.absoluteImageURL)) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color(hex: "2D1515"))
                        .frame(height: 180)
                        .overlay(ProgressView().tint(Color(hex: "7C6FCD")))
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(height: 180)
                        .clipped()
                        .overlay(
                            LinearGradient(
                                colors: [.clear, .clear, Color(hex: "1A1828").opacity(0.85)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                case .failure:
                    Rectangle()
                        .fill(Color(hex: "2D1515"))
                        .frame(height: 180)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundStyle(Color(hex: "6E6A8A"))
                        )
                @unknown default:
                    Rectangle().fill(Color(hex: "2D1515")).frame(height: 180)
                }
            }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14))
        }
    }
}
