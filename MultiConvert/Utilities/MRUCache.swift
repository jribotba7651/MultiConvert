import Foundation

struct MRUCache<T: Hashable & Codable>: Codable {
    private(set) var items: [T]
    let capacity: Int

    init(capacity: Int, items: [T] = []) {
        self.capacity = capacity
        self.items = items
    }

    mutating func use(_ item: T) {
        items.removeAll { $0 == item }
        items.insert(item, at: 0)
        if items.count > capacity {
            items = Array(items.prefix(capacity))
        }
    }

    mutating func remove(_ item: T) {
        items.removeAll { $0 == item }
    }

    mutating func clear() {
        items.removeAll()
    }

    var isEmpty: Bool { items.isEmpty }
    var count: Int { items.count }
}
