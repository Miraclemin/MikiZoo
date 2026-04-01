import Foundation

// MARK: - Provider

enum AgentProvider: String, CaseIterable {
    case claude, codex, copilot, openclaw

    private static let defaultsKey = "selectedProvider"

    static var current: AgentProvider {
        get {
            let raw = UserDefaults.standard.string(forKey: defaultsKey) ?? "claude"
            return AgentProvider(rawValue: raw) ?? .claude
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
        }
    }

    var displayName: String {
        switch self {
        case .claude:   return "Claude"
        case .codex:    return "Codex"
        case .copilot:  return "Copilot"
        case .openclaw: return "OpenClaw"
        }
    }

    var inputPlaceholder: String {
        "Ask \(displayName)..."
    }

    /// Returns provider name styled per theme format.
    func titleString(format: TitleFormat) -> String {
        switch format {
        case .uppercase:      return displayName.uppercased()
        case .lowercaseTilde: return "\(displayName.lowercased()) ~"
        case .capitalized:    return displayName
        }
    }

    var installInstructions: String {
        switch self {
        case .claude:
            return "To install, run this in Terminal:\n  curl -fsSL https://claude.ai/install.sh | sh\n\nOr download from https://claude.ai/download"
        case .codex:
            return "To install, run this in Terminal:\n  npm install -g @openai/codex"
        case .copilot:
            return "To install, run this in Terminal:\n  brew install copilot-cli\n\nOr: npm install -g @github/copilot-cli"
        case .openclaw:
            return "OpenClaw is not running.\n\nStart with:\n  openclaw gateway\n\nOr install from https://openclaw.ai"
        }
    }

    func createSession() -> any AgentSession {
        switch self {
        case .claude:   return ClaudeSession()
        case .codex:    return CodexSession()
        case .copilot:  return CopilotSession()
        case .openclaw: return OpenClawSession()
        }
    }

    // MARK: - OpenClaw Configuration

    static var openClawBaseURL: String {
        get { UserDefaults.standard.string(forKey: "openClawBaseURL") ?? "http://localhost:18789" }
        set { UserDefaults.standard.set(newValue, forKey: "openClawBaseURL") }
    }
    static var openClawAgentID: String {
        get { UserDefaults.standard.string(forKey: "openClawAgentID") ?? "openclaw" }
        set { UserDefaults.standard.set(newValue, forKey: "openClawAgentID") }
    }
    static var openClawToken: String {
        get { UserDefaults.standard.string(forKey: "openClawToken") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "openClawToken") }
    }
}

// MARK: - Title Format

enum TitleFormat {
    case uppercase       // "CLAUDE"
    case lowercaseTilde  // "claude ~"
    case capitalized     // "Claude"
}

// MARK: - Message

struct AgentMessage {
    enum Role { case user, assistant, error, toolUse, toolResult }
    let role: Role
    let text: String
}

// MARK: - Session Protocol

protocol AgentSession: AnyObject {
    var isRunning: Bool { get }
    var isBusy: Bool { get }
    var history: [AgentMessage] { get }
    /// Optional system prompt injected at session start (e.g. character persona).
    var systemPrompt: String? { get set }

    var onText: ((String) -> Void)? { get set }
    var onError: ((String) -> Void)? { get set }
    var onToolUse: ((String, [String: Any]) -> Void)? { get set }
    var onToolResult: ((String, Bool) -> Void)? { get set }
    var onSessionReady: (() -> Void)? { get set }
    var onTurnComplete: (() -> Void)? { get set }
    var onProcessExit: (() -> Void)? { get set }

    func start()
    func send(message: String)
    func terminate()
}
