import Foundation
import SwiftUI

/// Persists bookmarked news articles to disk so they're available offline.
@MainActor
final class BookmarksStore: ObservableObject {
    static let shared = BookmarksStore()

    @Published private(set) var articles: [NewsArticle] = []

    private let key = "pebb_bookmarks_v1"

    private init() { load() }

    func isBookmarked(_ article: NewsArticle) -> Bool {
        articles.contains { $0.slug == article.slug }
    }

    func toggle(_ article: NewsArticle) {
        if isBookmarked(article) {
            articles.removeAll { $0.slug == article.slug }
        } else {
            articles.insert(article, at: 0)
        }
        save()
    }

    func remove(_ article: NewsArticle) {
        articles.removeAll { $0.slug == article.slug }
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([NewsArticle].self, from: data) else { return }
        articles = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(articles) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
