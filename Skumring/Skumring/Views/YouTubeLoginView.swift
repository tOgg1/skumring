import SwiftUI
import WebKit

struct YouTubeLoginView: NSViewRepresentable {
    let startURL: URL

    init(startURL: URL = URL(string: "https://www.youtube.com/account")!) {
        self.startURL = startURL
    }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = YouTubeWebViewConfig.makeConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = YouTubeWebViewConfig.userAgent
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.load(URLRequest(url: startURL))
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
            }
            return nil
        }
    }
}
