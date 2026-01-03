import SwiftUI
import WebKit

/// SwiftUI wrapper for WKWebView that embeds a YouTube player via IFrame API
struct YouTubePlayerView: NSViewRepresentable {
    let player: YouTubePlayer
    
    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // Enable JavaScript
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        
        // Set up the user content controller for JS -> Swift messages
        let contentController = configuration.userContentController
        contentController.add(context.coordinator, name: "youtubePlayer")
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        // Set a standard Safari User-Agent to avoid YouTube blocking
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        
        // Allow inspection in Safari Developer Tools (debug only)
        #if DEBUG
        if webView.responds(to: Selector(("setInspectable:"))) {
            webView.perform(Selector(("setInspectable:")), with: true)
        }
        #endif
        
        // Load YouTube via direct embed URL
        loadYouTubeEmbed(webView: webView, videoID: player.videoID, autoplay: player.autoplay, loop: player.loop)
        
        context.coordinator.webView = webView
        
        return webView
    }
    
    func updateNSView(_ webView: WKWebView, context: Context) {
        if context.coordinator.currentVideoID != player.videoID {
            context.coordinator.currentVideoID = player.videoID
            loadYouTubeEmbed(webView: webView, videoID: player.videoID, autoplay: player.autoplay, loop: player.loop)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(player: player)
    }
    
    // MARK: - Load YouTube Embed
    
    private func loadYouTubeEmbed(webView: WKWebView, videoID: String, autoplay: Bool, loop: Bool) {
        // Load the full YouTube watch page instead of embed
        // This works around embed restrictions in WKWebView
        let urlString = "https://www.youtube.com/watch?v=\(videoID)"
        
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    // MARK: - Coordinator
    
    @MainActor
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let player: YouTubePlayer
        weak var webView: WKWebView?
        var currentVideoID: String
        private var isReady = false
        
        init(player: YouTubePlayer) {
            self.player = player
            self.currentVideoID = player.videoID
            super.init()
            
            // Set up command callbacks
            player.onPlay = { [weak self] in
                self?.executeJS("document.querySelector('video')?.play()")
            }
            player.onPause = { [weak self] in
                self?.executeJS("document.querySelector('video')?.pause()")
            }
            player.onSeek = { [weak self] (seconds: Double) in
                self?.executeJS("var v = document.querySelector('video'); if(v) v.currentTime = \(seconds)")
            }
            player.onSetVolume = { [weak self] (volume: Int) in
                let vol = Double(volume) / 100.0
                self?.executeJS("var v = document.querySelector('video'); if(v) v.volume = \(vol)")
            }
        }
        
        private func executeJS(_ script: String) {
            webView?.evaluateJavaScript(script) { _, error in
                if let error = error {
                    print("[YouTubePlayer] JS error: \(error.localizedDescription)")
                }
            }
        }
        
        // MARK: - WKNavigationDelegate
        
        nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            Task { @MainActor in
                // Inject CSS to hide YouTube UI and monitor player state
                self.injectCleanPlayerUI()
                self.injectStateMonitor()
            }
        }
        
        @MainActor
        private func injectCleanPlayerUI() {
            // Hide everything except the video player
            let cssScript = """
            (function() {
                var style = document.createElement('style');
                style.textContent = `
                    /* Hide header */
                    #masthead, #masthead-container, ytd-masthead { display: none !important; }
                    
                    /* Hide sidebar and secondary content */
                    #secondary, #related, ytd-watch-next-secondary-results-renderer { display: none !important; }
                    
                    /* Hide comments */
                    #comments, ytd-comments { display: none !important; }
                    
                    /* Hide below-player content */
                    #below, ytd-watch-metadata, #meta, #info, #description { display: none !important; }
                    
                    /* Hide guide/sidebar menu */
                    #guide, #guide-button, ytd-guide-renderer, tp-yt-app-drawer { display: none !important; }
                    
                    /* Hide bottom bar on mobile */
                    ytd-pivot-bar-renderer, ytd-mini-guide-renderer { display: none !important; }
                    
                    /* Hide chips/filters */
                    #chip-bar, ytd-feed-filter-chip-bar-renderer { display: none !important; }
                    
                    /* Make player full width */
                    #primary, #primary-inner, ytd-watch-flexy { 
                        max-width: 100% !important; 
                        padding: 0 !important;
                        margin: 0 !important;
                    }
                    
                    /* Expand player container */
                    #player-container, #player-container-inner, #player {
                        width: 100vw !important;
                        max-width: 100vw !important;
                    }
                    
                    /* Video player itself */
                    #movie_player, .html5-video-container, video {
                        width: 100% !important;
                        height: 100vh !important;
                        max-height: 100vh !important;
                    }
                    
                    /* Remove page margins */
                    ytd-app, #content, ytd-page-manager {
                        margin: 0 !important;
                        padding: 0 !important;
                    }
                    
                    /* Hide scrollbar */
                    body, html {
                        overflow: hidden !important;
                        background: #000 !important;
                    }
                    
                    /* Hide any popups/modals */
                    ytd-popup-container, tp-yt-iron-overlay-backdrop, .ytd-popup-container { display: none !important; }
                    
                    /* Hide end screen recommendations */
                    .ytp-ce-element, .ytp-endscreen-content { display: none !important; }
                `;
                document.head.appendChild(style);
                
                // Try to enter theater mode for better sizing
                setTimeout(function() {
                    var theaterBtn = document.querySelector('.ytp-size-button');
                    if (theaterBtn) theaterBtn.click();
                }, 2000);
            })();
            """
            
            webView?.evaluateJavaScript(cssScript) { _, error in
                if let error = error {
                    print("[YouTubePlayer] CSS injection error: \(error.localizedDescription)")
                }
            }
        }
        
        @MainActor
        private func injectStateMonitor() {
            // Wait for the video element and set up monitoring
            let monitorScript = """
            (function() {
                function setupMonitor() {
                    var video = document.querySelector('video');
                    if (!video) {
                        setTimeout(setupMonitor, 500);
                        return;
                    }
                    
                    // Signal ready
                    window.webkit.messageHandlers.youtubePlayer.postMessage({
                        type: 'ready',
                        data: { duration: video.duration || 0 }
                    });
                    
                    // Monitor state changes
                    video.addEventListener('play', function() {
                        window.webkit.messageHandlers.youtubePlayer.postMessage({
                            type: 'stateChange',
                            data: { state: 1 }
                        });
                    });
                    
                    video.addEventListener('pause', function() {
                        window.webkit.messageHandlers.youtubePlayer.postMessage({
                            type: 'stateChange',
                            data: { state: 2 }
                        });
                    });
                    
                    video.addEventListener('ended', function() {
                        window.webkit.messageHandlers.youtubePlayer.postMessage({
                            type: 'stateChange',
                            data: { state: 0 }
                        });
                    });
                    
                    video.addEventListener('waiting', function() {
                        window.webkit.messageHandlers.youtubePlayer.postMessage({
                            type: 'stateChange',
                            data: { state: 3 }
                        });
                    });
                    
                    // Time updates
                    setInterval(function() {
                        if (video) {
                            window.webkit.messageHandlers.youtubePlayer.postMessage({
                                type: 'timeUpdate',
                                data: {
                                    currentTime: video.currentTime || 0,
                                    duration: video.duration || 0
                                }
                            });
                        }
                    }, 500);
                }
                setupMonitor();
            })();
            """
            
            webView?.evaluateJavaScript(monitorScript) { _, error in
                if let error = error {
                    print("[YouTubePlayer] Monitor injection error: \(error.localizedDescription)")
                }
            }
        }
        
        nonisolated func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                player.updateError("Navigation failed: \(error.localizedDescription)")
            }
        }
        
        nonisolated func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            Task { @MainActor in
                player.updateError("Load failed: \(error.localizedDescription)")
            }
        }
        
        // MARK: - WKScriptMessageHandler
        
        nonisolated func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any],
                  let type = body["type"] as? String,
                  let data = body["data"] as? [String: Any] else {
                return
            }
            
            Task { @MainActor in
                self.handleMessage(type: type, data: data)
            }
        }
        
        @MainActor
        private func handleMessage(type: String, data: [String: Any]) {
            switch type {
            case "ready":
                player.updateReady(true)
                if let duration = data["duration"] as? Double, duration.isFinite {
                    player.updateTime(current: 0, duration: duration)
                }
                print("[YouTubePlayer] Ready")
                
            case "stateChange":
                if let stateRaw = data["state"] as? Int,
                   let state = YouTubePlayerState(rawValue: stateRaw) {
                    player.updateState(state)
                    print("[YouTubePlayer] State: \(state)")
                }
                
            case "timeUpdate":
                if let current = data["currentTime"] as? Double,
                   let duration = data["duration"] as? Double,
                   current.isFinite && duration.isFinite {
                    player.updateTime(current: current, duration: duration)
                }
                
            case "error":
                if let message = data["message"] as? String {
                    player.updateError(message)
                    print("[YouTubePlayer] Error: \(message)")
                }
                
            default:
                break
            }
        }
    }
}
