import SwiftUI

struct NewsTabView: View {
    @StateObject private var api = PebbAPI.shared
    @State private var selectedArticle: NewsArticle?
    @State private var showError = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                topBar
                if api.isLoadingNews {
                    Spacer()
                    ProgressView()
                        .tint(Color(hex: "7C6FCD"))
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
            .navigationDestination(item: $selectedArticle) { article in
                ArticleDetailView(article: article)
            }
            .alert("Couldn't load news", isPresented: $showError) {
                Button("OK") {}
            }
        }
    }

    private var topBar: some View {
        HStack {
            HStack(spacing: 9) {
                Image(systemName: "newspaper")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(hex: "F87171"))
                    .frame(width: 30, height: 30)
                    .background(Color(hex: "2D1515"))
                    .clipShape(RoundedRectangle(cornerRadius: 9))
                Text("Pebb News")
                    .font(.custom("Fraunces", size: 19).weight(.bold))
                    .foregroundColor(Color(hex: "EDEBF7"))
            }
            Spacer()
            Text("Real. Fast. Always On.")
                .font(.system(size: 10))
                .foregroundColor(Color(hex: "6E6A8A"))
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(Color(hex: "0B0A12").opacity(0.82))
        .overlay(Divider().overlay(Color(hex: "FFFFFF").opacity(0.07)), alignment: .bottom)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "newspaper")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "6E6A8A"))
            Text("No articles yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(hex: "EDEBF7"))
            Text("Daily news will appear here each morning.")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "6E6A8A"))
            Button("Refresh") {
                Task { try? await api.loadNews() }
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Color(hex: "7C6FCD"))
            Spacer()
        }
    }

    private var articlesList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(api.newsArticles) { article in
                    ArticleRow(article: article)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            articleImage
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(article.category)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "F87171"))
                        .textCase(.uppercase)
                    Text(article.source)
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "6E6A8A"))
                    Spacer()
                    Text(article.published_at.replacingOccurrences(of: " — .*", with: "", options: .regularExpression))
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "6E6A8A"))
                }
                Text(article.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "EDEBF7"))
                    .lineLimit(3)
                Text(article.summary)
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "A09CBA"))
                    .lineLimit(2)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(hex: "1A1828"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(hex: "FFFFFF").opacity(0.06), lineWidth: 1))
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
                case .failure:
                    Rectangle()
                        .fill(Color(hex: "2D1515"))
                        .frame(height: 180)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 32))
                                .foregroundColor(Color(hex: "6E6A8A"))
                        )
                @unknown default:
                    Rectangle()
                        .fill(Color(hex: "2D1515"))
                        .frame(height: 180)
                }
            }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 14, topTrailingRadius: 14))
        }
    }
}
