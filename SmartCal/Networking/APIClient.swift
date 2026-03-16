import Foundation

actor APIClient {
    static let shared = APIClient()
    private let decoder: JSONDecoder = JSONDecoder()
    private let encoder: JSONEncoder = JSONEncoder()

    private init() {}

    // MARK: - Tasks

    func getTasks() async throws -> [SCTask] {
        try await fetch(endpoint: .getTasks)
    }

    func createTask(_ task: NewTask) async throws -> SCTask {
        let body = try encoder.encode(task)
        return try await fetch(endpoint: .createTask, body: body)
    }

    func updateTask(id: Int, patch: TaskPatch) async throws -> SCTask {
        let body = try encoder.encode(patch)
        return try await fetch(endpoint: .updateTask(id: id), body: body)
    }

    func deleteTask(id: Int) async throws {
        try await send(endpoint: .deleteTask(id: id))
    }

    // MARK: - Constraints

    func getConstraints() async throws -> Constraints {
        try await fetch(endpoint: .getConstraints)
    }

    func updateConstraints(_ constraints: Constraints) async throws {
        let body = try encoder.encode(constraints)
        try await send(endpoint: .updateConstraints, body: body)
    }

    // MARK: - Planning

    func planToday() async throws -> DaySchedule {
        try await fetch(endpoint: .planToday)
    }

    func getPlan(date: String) async throws -> DaySchedule {
        try await fetch(endpoint: .getPlan(date: date))
    }

    func replan(date: String) async throws -> DaySchedule {
        try await fetch(endpoint: .replan(date: date))
    }

    // MARK: - Private helpers

    private func fetch<T: Decodable>(endpoint: Endpoint, body: Data? = nil) async throws -> T {
        let request = try endpoint.urlRequest(body: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    private func send(endpoint: Endpoint, body: Data? = nil) async throws {
        let request = try endpoint.urlRequest(body: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response: response, data: data)
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.httpError(http.statusCode, message)
        }
    }
}
