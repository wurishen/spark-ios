import Foundation

final class PersistenceService {
    private let fileName = "spark_save.json"
    private let defaultsKey = "spark.gameState.v1"

    private var fileURL: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return docs.appendingPathComponent(fileName)
    }

    func save(_ state: GameState) {
        do {
            let data = try JSONEncoder().encode(state)
            try data.write(to: fileURL, options: [.atomic])
            UserDefaults.standard.set(data, forKey: defaultsKey)
        } catch {
            // 回退到 UserDefaults
            if let data = try? JSONEncoder().encode(state) {
                UserDefaults.standard.set(data, forKey: defaultsKey)
            }
        }
    }

    func load() -> GameState? {
        if let data = try? Data(contentsOf: fileURL),
           let state = try? JSONDecoder().decode(GameState.self, from: data) {
            return sanitize(state)
        }
        if let data = UserDefaults.standard.data(forKey: defaultsKey),
           let state = try? JSONDecoder().decode(GameState.self, from: data) {
            return sanitize(state)
        }
        return nil
    }

    func clear() {
        try? FileManager.default.removeItem(at: fileURL)
        UserDefaults.standard.removeObject(forKey: defaultsKey)
    }

    /// 确保存档角色始终成年
    private func sanitize(_ state: GameState) -> GameState {
        var copy = state
        if let c = copy.character, c.age < 22 || c.age > 32 {
            copy.character = nil
            copy.hasPassedAgeGate = false
        }
        return copy
    }
}
