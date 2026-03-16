import Foundation

enum HTTPMethod: String {
    case GET, POST, PUT, PATCH, DELETE
}

enum Endpoint {
    case getTasks
    case getCompletedTasks
    case createTask
    case updateTask(id: Int)
    case deleteTask(id: Int)
    case getConstraints
    case updateConstraints
    case planToday
    case getPlan(date: String)
    case replan(date: String)

    static let baseURL = "https://43.205.131.137.nip.io"

    var path: String {
        switch self {
        case .getTasks, .createTask, .getCompletedTasks: return "/tasks"
        case .updateTask(let id), .deleteTask(let id): return "/tasks/\(id)"
        case .getConstraints, .updateConstraints: return "/constraints"
        case .planToday: return "/plan/today"
        case .getPlan(let date): return "/plan/\(date)"
        case .replan(let date): return "/plan/\(date)/replan"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .getTasks, .getCompletedTasks, .getConstraints, .getPlan: return .GET
        case .createTask, .planToday, .replan: return .POST
        case .updateConstraints: return .PUT
        case .updateTask: return .PATCH
        case .deleteTask: return .DELETE
        }
    }

    func urlRequest(body: Data? = nil) throws -> URLRequest {
        var components = URLComponents(string: Self.baseURL + path)
        if case .getCompletedTasks = self {
            components?.queryItems = [URLQueryItem(name: "status", value: "done")]
        }
        guard let url = components?.url else { throw APIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }
}

enum APIError: LocalizedError {
    case invalidURL
    case httpError(Int, String)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .httpError(let code, let message): return "Server error \(code): \(message)"
        case .decodingError(let error): return "Decode error: \(error.localizedDescription)"
        }
    }
}
