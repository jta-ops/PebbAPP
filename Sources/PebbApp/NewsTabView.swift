import SwiftUI

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
    @State private var selectedArticle: NewsArticle?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topBar
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
            .task { try? await api.loadNews() }
            .refreshable { try? await api.loadNews() }
            .navigationDestination(item: $selectedArticle) { ArticleDetailView(article: $0) }
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
            Text("Real. Fast. Always On.")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "6E6A8A"))
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .overlay(Divider().overlay(Color(hex: "FFFFFF").opacity(0.07)), alignment: .bottom)
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
                ForEach(Array(api.newsArticles.enumerated()), id: \.element.id) { index, article in
                    ArticleRow(article: article, index: index)
                        .onTapGesture { selectedArticle = article }
                        .padding(.horizontal, 14)
                }
            }
            .padding(.vertical, 12)
        }
        .scrollDismissesKeyboard(.immediately)
    }
}

struct ArticleRow: View {
    let article: NewsArticle
    let index: Int
    @State private var appear = false

    var catColor: Color { categoryColor(article.category) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            articleImage
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
        if !article.image_url.isEmpty {
            AsyncImage(url: URL(string: article.image_url)) { phase in
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
