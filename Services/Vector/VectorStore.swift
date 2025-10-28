import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

protocol VectorStore {
    func upsert(embedding: [Float], for spotId: String) throws
    func searchSimilar(to vector: [Float], topK: Int) throws -> [String]
}

enum VectorStoreError: Error {
    case initializationFailed
    case executionFailed
}

final class SQLiteVectorStore: VectorStore {
    struct Location {
        let url: URL

        static var defaultStore: Location {
            let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            return Location(url: url.appendingPathComponent("vector_store.sqlite"))
        }
    }

    private let db: OpaquePointer?

    init(location: Location) throws {
        if location.url.path != ":memory:" {
            try FileManager.default.createDirectory(at: location.url.deletingLastPathComponent(), withIntermediateDirectories: true)
        }
        var db: OpaquePointer?
        if sqlite3_open(location.url.path, &db) != SQLITE_OK {
            throw VectorStoreError.initializationFailed
        }
        self.db = db
        try createTable()
    }

    deinit {
        sqlite3_close(db)
    }

    private func createTable() throws {
        let sql = "CREATE TABLE IF NOT EXISTS vectors (spotId TEXT PRIMARY KEY, embedding BLOB NOT NULL, updatedAt REAL NOT NULL)"
        guard sqlite3_exec(db, sql, nil, nil, nil) == SQLITE_OK else {
            throw VectorStoreError.executionFailed
        }
    }

    func upsert(embedding: [Float], for spotId: String) throws {
        let sql = "INSERT OR REPLACE INTO vectors (spotId, embedding, updatedAt) VALUES (?, ?, ?)"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw VectorStoreError.executionFailed
        }
        defer { sqlite3_finalize(statement) }

        (spotId as NSString).utf8String?.withMemoryRebound(to: Int8.self, capacity: spotId.utf8.count + 1) { pointer in
            sqlite3_bind_text(statement, 1, pointer, -1, SQLITE_TRANSIENT)
        }
        var copy = embedding
        copy.withUnsafeBytes { bytes in
            sqlite3_bind_blob(statement, 2, bytes.baseAddress, Int32(bytes.count), SQLITE_TRANSIENT)
        }
        sqlite3_bind_double(statement, 3, Date().timeIntervalSince1970)

        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw VectorStoreError.executionFailed
        }
    }

    func searchSimilar(to vector: [Float], topK: Int) throws -> [String] {
        let sql = "SELECT spotId, embedding FROM vectors"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else {
            throw VectorStoreError.executionFailed
        }
        defer { sqlite3_finalize(statement) }

        var results: [(String, Double)] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let cString = sqlite3_column_text(statement, 0) else { continue }
            let spotId = String(cString: cString)
            guard let blob = sqlite3_column_blob(statement, 1) else { continue }
            let length = Int(sqlite3_column_bytes(statement, 1))
            let count = length / MemoryLayout<Float>.stride
            let pointer = blob.bindMemory(to: Float.self, capacity: count)
            let embedding = Array(UnsafeBufferPointer(start: pointer, count: count))
            let score = cosineSimilarity(vector, embedding)
            results.append((spotId, score))
        }

        return results.sorted { $0.1 > $1.1 }.prefix(topK).map { $0.0 }
    }

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count else { return 0 }
        var dot: Double = 0
        var normA: Double = 0
        var normB: Double = 0
        for index in 0..<a.count {
            dot += Double(a[index] * b[index])
            normA += Double(a[index] * a[index])
            normB += Double(b[index] * b[index])
        }
        guard normA > 0, normB > 0 else { return 0 }
        return dot / (sqrt(normA) * sqrt(normB))
    }
}

extension SQLiteVectorStore {
    static func inMemory() throws -> SQLiteVectorStore {
        try SQLiteVectorStore(location: Location(url: URL(fileURLWithPath: ":memory:")))
    }
}
