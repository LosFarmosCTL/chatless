struct CostLRUCache<Key: Hashable, Value> {
  private struct Entry {
    let value: Value
    let cost: Int
    var previous: Key?
    var next: Key?
  }

  private var entries: [Key: Entry] = [:]
  private var oldest: Key?
  private var newest: Key?

  private(set) var costLimit: Int
  private(set) var totalCost = 0
  private(set) var evictionCount = 0

  init(costLimit: Int) {
    self.costLimit = max(costLimit, 0)
  }

  mutating func value(for key: Key) -> Value? {
    guard let entry = entries[key] else { return nil }

    detach(key, entry: entry)
    append(key)

    return entry.value
  }

  mutating func take(_ key: Key) -> Value? {
    guard let entry = entries.removeValue(forKey: key) else { return nil }

    detach(key, entry: entry)
    totalCost -= entry.cost

    return entry.value
  }

  mutating func insert(_ value: Value, for key: Key, cost: Int) {
    _ = take(key)
    let cost = max(cost, 0)
    entries[key] = Entry(value: value, cost: cost)
    totalCost += cost
    append(key)
    trim()
  }

  mutating func setCostLimit(_ limit: Int) {
    costLimit = max(limit, 0)
    trim()
  }

  mutating func removeAll() {
    entries.removeAll()
    oldest = nil
    newest = nil
    totalCost = 0
  }

  private mutating func trim() {
    while totalCost > costLimit, let key = oldest {
      _ = take(key)
      evictionCount += 1
    }
  }

  private mutating func append(_ key: Key) {
    entries[key]?.previous = newest
    entries[key]?.next = nil

    if let newest {
      entries[newest]?.next = key
    } else {
      oldest = key
    }

    newest = key
  }

  private mutating func detach(_ key: Key, entry: Entry) {
    if let previous = entry.previous {
      entries[previous]?.next = entry.next
    } else {
      oldest = entry.next
    }

    if let next = entry.next {
      entries[next]?.previous = entry.previous
    } else {
      newest = entry.previous
    }
  }
}
