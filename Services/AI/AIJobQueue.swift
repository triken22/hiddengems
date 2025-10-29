import Foundation

actor AIJobQueue {
    func enqueue<Result>(_ work: @escaping () async throws -> Result) async throws -> Result {
        var delay: UInt64 = 1_000_000_000
        let maxDelay: UInt64 = 60_000_000_000
        while true {
            do {
                return try await work()
            } catch {
                if delay >= maxDelay {
                    throw error
                }
                try await Task.sleep(nanoseconds: delay)
                delay = min(delay * 2, maxDelay)
            }
        }
    }
}
