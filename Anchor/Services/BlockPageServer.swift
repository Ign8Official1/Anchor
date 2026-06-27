import Foundation
import Network

final class BlockPageServer {
    static let shared = BlockPageServer()
    static let port: UInt16 = 52941

    private var listener: NWListener?
    private(set) var isRunning = false
    private let queue = DispatchQueue(label: "com.anchor.blockpage")

    private init() {}

    func startIfNeeded() {
        guard !isRunning else { return }
        guard let nwPort = NWEndpoint.Port(rawValue: Self.port) else { return }

        do {
            let listener = try NWListener(using: .tcp, on: nwPort)
            listener.newConnectionHandler = { [weak self] connection in
                self?.handle(connection: connection)
            }
            listener.stateUpdateHandler = { [weak self] state in
                if case .ready = state {
                    DispatchQueue.main.async { self?.isRunning = true }
                }
                if case .failed = state {
                    DispatchQueue.main.async {
                        self?.isRunning = false
                        self?.listener = nil
                    }
                }
            }
            listener.start(queue: queue)
            self.listener = listener
        } catch {
            isRunning = false
        }
    }

    func stop() {
        listener?.cancel()
        listener = nil
        isRunning = false
    }

    func pageURL(for domain: String, quote: BlockQuote = QuoteLibrary.random()) -> String {
        startIfNeeded()
        var parts = URLComponents()
        parts.scheme = "http"
        parts.host = "127.0.0.1"
        parts.port = Int(Self.port)
        parts.path = "/block.html"
        parts.queryItems = [
            URLQueryItem(name: "domain", value: domain),
            URLQueryItem(name: "quote", value: quote.text),
            URLQueryItem(name: "attr", value: quote.attribution),
        ]
        return parts.url?.absoluteString ?? "http://127.0.0.1:\(Self.port)/block.html?domain=\(domain)"
    }

    var baseURLPrefix: String {
        "http://127.0.0.1:\(Self.port)/"
    }

    private func handle(connection: NWConnection) {
        connection.start(queue: queue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, _, _ in
            guard let self, let data, let request = String(data: data, encoding: .utf8) else {
                connection.cancel()
                return
            }
            let response = self.response(for: request)
            connection.send(content: response, completion: .contentProcessed { _ in
                connection.cancel()
            })
        }
    }

    private func response(for request: String) -> Data {
        let lines = request.split(separator: "\r\n", maxSplits: 1)
        guard let requestLine = lines.first else { return notFound() }
        let parts = requestLine.split(separator: " ")
        guard parts.count >= 2 else { return notFound() }

        let path = String(parts[1]).split(separator: "?").first.map(String.init) ?? "/"
        let cleanPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if cleanPath.isEmpty || cleanPath == "block.html" {
            if let url = Bundle.main.url(forResource: "block", withExtension: "html"),
               let body = try? Data(contentsOf: url) {
                return httpResponse(body: body, contentType: "text/html; charset=utf-8")
            }
        }

        if cleanPath == "Lockedvid.mp4" {
            if let url = Bundle.main.url(forResource: "Lockedvid", withExtension: "mp4"),
               let body = try? Data(contentsOf: url) {
                return httpResponse(body: body, contentType: "video/mp4")
            }
        }

        return notFound()
    }

    private func httpResponse(body: Data, contentType: String) -> Data {
        var header = "HTTP/1.1 200 OK\r\n"
        header += "Content-Type: \(contentType)\r\n"
        header += "Content-Length: \(body.count)\r\n"
        header += "Connection: close\r\n"
        header += "Cache-Control: no-store\r\n"
        header += "\r\n"
        var data = Data(header.utf8)
        data.append(body)
        return data
    }

    private func notFound() -> Data {
        let body = Data("Not found".utf8)
        var header = "HTTP/1.1 404 Not Found\r\n"
        header += "Content-Type: text/plain\r\n"
        header += "Content-Length: \(body.count)\r\n"
        header += "Connection: close\r\n\r\n"
        var data = Data(header.utf8)
        data.append(body)
        return data
    }
}
