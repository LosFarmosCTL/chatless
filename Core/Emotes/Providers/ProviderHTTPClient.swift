import Foundation

enum ProviderHTTPClient {
  enum RequestError: Error {
    case invalidResponse
    case statusCode(Int)
  }

  static func data(from url: URL) async throws -> Data {
    var request = URLRequest(url: url)
    request.timeoutInterval = 20
    request.setValue("Chatless/1.0", forHTTPHeaderField: "User-Agent")
    let (data, response) = try await URLSession.shared.data(for: request)

    guard let response = response as? HTTPURLResponse else {
      throw RequestError.invalidResponse
    }

    guard (200..<300).contains(response.statusCode) else {
      throw RequestError.statusCode(response.statusCode)
    }

    return data
  }
}
