import SwiftUI
import WebKit

final class AureliaSchemeHandler: NSObject, WKURLSchemeHandler {
    let rootURL: URL

    init(rootURL: URL) {
        self.rootURL = rootURL
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else { return }

        var path = url.path
        if path.hasPrefix("/") { path.removeFirst() }
        if path.isEmpty { path = "anchor-embed.html" }

        let fileURL = rootURL.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: fileURL) else {
            urlSchemeTask.didFailWithError(
                NSError(domain: "Aurelia", code: 404, userInfo: [NSLocalizedDescriptionKey: "Missing \(path)"])
            )
            return
        }

        let mime = Self.mimeType(for: fileURL.pathExtension)
        let response = URLResponse(
            url: url,
            mimeType: mime,
            expectedContentLength: data.count,
            textEncodingName: Self.isTextMime(mime) ? "utf-8" : nil
        )
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didReceive(data)
        urlSchemeTask.didFinish()
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

    private static func mimeType(for ext: String) -> String {
        switch ext.lowercased() {
        case "html": return "text/html"
        case "js": return "text/javascript"
        case "css": return "text/css"
        case "json": return "application/json"
        case "wasm": return "application/wasm"
        default: return "application/octet-stream"
        }
    }

    private static func isTextMime(_ mime: String) -> Bool {
        mime.hasPrefix("text/") || mime == "application/javascript"
    }
}

@MainActor
final class OceanPrewarmer {
    static let shared = OceanPrewarmer()

    private var webView: WKWebView?
    private var schemeHandler: AureliaSchemeHandler?

    private init() {}

    func start() {
        guard webView == nil, let bundleRoot = aureliaBundleURL else { return }

        let configuration = WKWebViewConfiguration()
        let handler = AureliaSchemeHandler(rootURL: bundleRoot)
        schemeHandler = handler
        configuration.setURLSchemeHandler(handler, forURLScheme: "anchor-aurelia")

        let view = WKWebView(frame: CGRect(x: 0, y: 0, width: 1280, height: 800), configuration: configuration)
        view.setValue(false, forKey: "drawsBackground")
        if let url = URL(string: "anchor-aurelia://bundle/anchor-embed.html?jellyfish=6") {
            view.load(URLRequest(url: url))
        }
        webView = view
    }

    func takeWebView() -> WKWebView? {
        webView
    }

    private var aureliaBundleURL: URL? {
        if let url = Bundle.main.url(forResource: "anchor-embed", withExtension: "html", subdirectory: "aurelia") {
            return url.deletingLastPathComponent()
        }
        return Bundle.main.resourceURL?.appendingPathComponent("aurelia", isDirectory: true)
    }
}

@MainActor
final class OceanWebViewHolder {
    static let shared = OceanWebViewHolder()
    private(set) weak var webView: WKWebView?

    private init() {}

    func claim(_ view: WKWebView) {
        webView = view
    }

    var hasLiveOcean: Bool {
        webView != nil
    }
}

struct AureliaOceanWebView: NSViewRepresentable {
    var sessionActive: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> WKWebView {
        if let prewarmed = OceanPrewarmer.shared.takeWebView() {
            prewarmed.navigationDelegate = context.coordinator
            context.coordinator.webView = prewarmed
            context.coordinator.sessionActive = sessionActive
            OceanWebViewHolder.shared.claim(prewarmed)
            context.coordinator.markReadyIfCanvasPresent(in: prewarmed)
            return prewarmed
        }

        if OceanWebViewHolder.shared.hasLiveOcean {
            let configuration = WKWebViewConfiguration()
            let stub = WKWebView(frame: .zero, configuration: configuration)
            stub.isHidden = true
            stub.alphaValue = 0
            return stub
        }

        let configuration = WKWebViewConfiguration()

        if let bundleRoot = Self.aureliaBundleURL {
            let handler = AureliaSchemeHandler(rootURL: bundleRoot)
            context.coordinator.schemeHandler = handler
            configuration.setURLSchemeHandler(handler, forURLScheme: "anchor-aurelia")
        }

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsMagnification = false
        webView.allowsBackForwardNavigationGestures = false
        webView.navigationDelegate = context.coordinator

        context.coordinator.webView = webView
        context.coordinator.sessionActive = sessionActive
        OceanWebViewHolder.shared.claim(webView)
        loadOcean(in: webView, coordinator: context.coordinator)

        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.sessionActive = sessionActive
        context.coordinator.scheduleResize(webView)
        guard context.coordinator.isReady else { return }
        pushSessionState(to: webView, active: sessionActive)
    }

    private func resizeWebViewIfNeeded(_ webView: WKWebView, coordinator: Coordinator) {
        let size = webView.bounds.size
        guard size.width > 2, size.height > 2, size != coordinator.lastSize else { return }
        coordinator.lastSize = size
        let script = "window.__ANCHOR_OCEAN__?.resize(\(size.width), \(size.height));"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    private static var aureliaBundleURL: URL? {
        if let url = Bundle.main.url(forResource: "anchor-embed", withExtension: "html", subdirectory: "aurelia") {
            return url.deletingLastPathComponent()
        }
        return Bundle.main.resourceURL?.appendingPathComponent("aurelia", isDirectory: true)
    }

    private func loadOcean(in webView: WKWebView, coordinator: Coordinator) {
        guard Self.aureliaBundleURL != nil,
              let pageURL = URL(string: "anchor-aurelia://bundle/anchor-embed.html?jellyfish=6") else {
            return
        }
        webView.load(URLRequest(url: pageURL))
    }

    private func pushSessionState(to webView: WKWebView, active: Bool) {
        let script = "window.__ANCHOR_OCEAN__?.setSessionActive(\(active));"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var webView: WKWebView?
        var schemeHandler: AureliaSchemeHandler?
        var isReady = false
        var sessionActive = false
        var lastSize = CGSize.zero
        private var resizeWorkItem: DispatchWorkItem?

        func scheduleResize(_ webView: WKWebView) {
            resizeWorkItem?.cancel()
            let work = DispatchWorkItem { [weak self, weak webView] in
                guard let self, let webView else { return }
                let size = webView.bounds.size
                guard size.width > 2, size.height > 2, size != self.lastSize else { return }
                self.lastSize = size
                let script = "window.__ANCHOR_OCEAN__?.resize(\(size.width), \(size.height));"
                webView.evaluateJavaScript(script, completionHandler: nil)
            }
            resizeWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: work)
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            markReadyIfCanvasPresent(in: webView)
        }

        func markReadyIfCanvasPresent(in webView: WKWebView) {
            webView.evaluateJavaScript("!!document.querySelector('canvas')") { result, _ in
                self.isReady = (result as? Bool) == true
                if self.isReady {
                    self.scheduleResize(webView)
                    self.pushSessionState(to: webView, active: self.sessionActive)
                }
            }
        }

        private func pushSessionState(to webView: WKWebView, active: Bool) {
            let script = "window.__ANCHOR_OCEAN__?.setSessionActive(\(active));"
            webView.evaluateJavaScript(script, completionHandler: nil)
        }
    }
}
