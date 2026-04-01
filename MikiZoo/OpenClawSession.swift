import Foundation

class OpenClawSession: NSObject, AgentSession, URLSessionDataDelegate {
    private var urlSession: URLSession!
    private var currentTask: URLSessionDataTask?
    private var currentResponseText = ""
    private var sseBuffer = ""

    private(set) var isRunning = false
    private(set) var isBusy = false

    var onText: ((String) -> Void)?
    var onError: ((String) -> Void)?
    var onToolUse: ((String, [String: Any]) -> Void)?
    var onToolResult: ((String, Bool) -> Void)?
    var onSessionReady: (() -> Void)?
    var onTurnComplete: (() -> Void)?
    var onProcessExit: (() -> Void)?

    var systemPrompt: String?
    var history: [AgentMessage] = []

    override init() {
        super.init()
        makeSession()
    }

    private func makeSession() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    // MARK: - AgentSession

    func start() {
        let baseURL = AgentProvider.openClawBaseURL
        guard let url = URL(string: "\(baseURL)/healthz") else {
            fireError("Invalid OpenClaw URL: \(baseURL)")
            return
        }
        var request = URLRequest(url: url, timeoutInterval: 5)
        request.setValue("operator.read", forHTTPHeaderField: "x-openclaw-scopes")
        addAuth(&request)

        urlSession.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                guard let self else { return }
                if let error {
                    let msg = "Cannot connect to OpenClaw at \(baseURL)\n\nMake sure it's running:\n  openclaw gateway\n\n\(AgentProvider.openclaw.installInstructions)\n\nError: \(error.localizedDescription)"
                    self.fireError(msg)
                    return
                }
                self.isRunning = true
                self.onSessionReady?()
            }
        }.resume()
    }

    func send(message: String) {
        guard isRunning else { return }
        isBusy = true
        currentResponseText = ""
        sseBuffer = ""
        history.append(AgentMessage(role: .user, text: message))

        let baseURL = AgentProvider.openClawBaseURL
        let agentID  = AgentProvider.openClawAgentID
        guard let url = URL(string: "\(baseURL)/v1/chat/completions") else { return }

        // Build full message history for context
        var messages: [[String: String]] = []
        if let sys = systemPrompt, !sys.isEmpty {
            messages.append(["role": "system", "content": sys])
        }
        for msg in history {
            switch msg.role {
            case .user:      messages.append(["role": "user",      "content": msg.text])
            case .assistant: messages.append(["role": "assistant", "content": msg.text])
            default: break
            }
        }

        let body: [String: Any] = ["model": agentID, "stream": true, "messages": messages]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("operator.write", forHTTPHeaderField: "x-openclaw-scopes")
        addAuth(&request)

        currentTask = urlSession.dataTask(with: request)
        currentTask?.resume()
    }

    func terminate() {
        currentTask?.cancel()
        currentTask = nil
        urlSession.invalidateAndCancel()
        makeSession()
        isRunning = false
        isBusy = false
    }

    // MARK: - URLSessionDataDelegate (SSE streaming)

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        sseBuffer += text
        while let nl = sseBuffer.range(of: "\n") {
            let line = String(sseBuffer[sseBuffer.startIndex..<nl.lowerBound])
            sseBuffer = String(sseBuffer[nl.upperBound...])
            guard line.hasPrefix("data: ") else { continue }
            let payload = String(line.dropFirst(6))
            DispatchQueue.main.async { self.processSSE(payload) }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            if let err = error as NSError?, err.code != NSURLErrorCancelled {
                self.fireError(err.localizedDescription)
            }
            if self.isBusy { self.finishTurn() }
        }
    }

    // MARK: - SSE parsing

    private func processSSE(_ payload: String) {
        if payload == "[DONE]" {
            finishTurn()
            return
        }
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let delta = choices.first?["delta"] as? [String: Any],
              let content = delta["content"] as? String,
              !content.isEmpty else { return }

        currentResponseText += content
        onText?(content)
    }

    private func finishTurn() {
        isBusy = false
        if !currentResponseText.isEmpty {
            history.append(AgentMessage(role: .assistant, text: currentResponseText))
            currentResponseText = ""
        }
        onTurnComplete?()
    }

    private func fireError(_ msg: String) {
        onError?(msg)
        history.append(AgentMessage(role: .error, text: msg))
        isBusy = false
    }

    private func addAuth(_ request: inout URLRequest) {
        let token = OpenClawSession.resolvedToken()
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    /// Returns the token to use: user-configured first, then auto-detected from ~/.openclaw/openclaw.json.
    static func resolvedToken() -> String {
        let stored = AgentProvider.openClawToken
        if !stored.isEmpty { return stored }
        // Auto-detect from openclaw config
        let configPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".openclaw/openclaw.json")
        guard let data = try? Data(contentsOf: configPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let gateway = json["gateway"] as? [String: Any],
              let auth = gateway["auth"] as? [String: Any],
              let token = auth["token"] as? String,
              !token.isEmpty else { return "" }
        return token
    }
}
