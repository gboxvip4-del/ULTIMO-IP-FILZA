import Combine
import Foundation

@MainActor
final class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var isRevalidating = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var accessKey = ""

    private let validationEndpoint = URL(string: "https://gboxiosvip.com.br/api/check_ios.php")!

    private enum ValidationResult {
        case allowed
        case denied(String)
        case offline(String)
    }

    init() {}

    func login() async {
        guard !isLoading, !isRevalidating else { return }
        let key = accessKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            isAuthenticated = false
            showError = true
            errorMessage = "Informe sua chave de acesso."
            return
        }
        isLoading = true
        defer { isLoading = false }

        let result: ValidationResult
        result = await validateAccessKey(key)

        switch result {
        case .allowed:
            markSessionAuthorized()
        case .denied(let message):
            isAuthenticated = false
            showError = true
            errorMessage = message
        case .offline(let message):
            isAuthenticated = false
            showError = true
            errorMessage = message
        }
    }

    /// Sends only the access key. The API identifies the request IP and checks
    /// whether that IP was released externally for this key.
    private func validateAccessKey(_ key: String) async -> ValidationResult {
        var form = URLComponents()
        form.queryItems = [URLQueryItem(name: "key", value: key)]
        guard let body = form.percentEncodedQuery?.data(using: .utf8) else {
            return .offline("Não foi possível preparar a validação da chave.")
        }

        var request = URLRequest(url: validationEndpoint)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20
        // Do not log the request body because it contains the access key.
        log("[AUTH] POST GBOX key validation")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            log("[AUTH] key validation network error")
            return .offline(offlineMessage(for: error))
        }

        guard let http = response as? HTTPURLResponse else {
            log("[AUTH] key validation returned a non-HTTP response")
            return .offline("Erro de conexão com o servidor de validação.")
        }

        log("[AUTH] key validation HTTP status=\(http.statusCode)")
        let payload = Self.parseJSONObject(data)
        if (200...299).contains(http.statusCode) {
            if Self.stringFromPayload(payload, keys: ["status"]).lowercased() == "success" {
                return .allowed
            }
            if Self.explicitlyDeniesAccess(payload: payload, responseBody: data) {
                return .denied(Self.denialMessage(for: http.statusCode, payload: payload))
            }
            return .denied(Self.messageFromPayload(
                payload,
                fallback: "IP não liberado."
            ))
        }
        if http.statusCode == 429 {
            return .offline(Self.messageFromPayload(payload, fallback: "Muitas tentativas. Aguarde e tente novamente."))
        }
        if (500...599).contains(http.statusCode) {
            return .offline(Self.messageFromPayload(
                payload,
                fallback: "A API GBOX está indisponível no momento (HTTP \(http.statusCode)). Tente novamente mais tarde."
            ))
        }
        return .denied(Self.denialMessage(for: http.statusCode, payload: payload))
    }

    private func markSessionAuthorized() {
        isAuthenticated = true
        showError = false
        errorMessage = ""
    }

    private func clearSavedSession() {
        isAuthenticated = false
    }

    func logout() {
        clearSavedSession()
        showError = false
        errorMessage = ""
    }

    private static func parseJSONObject(_ data: Data) -> [String: Any] {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        return object
    }

    private static func messageFromPayload(_ payload: [String: Any], fallback: String) -> String {
        let message = stringFromPayload(payload, keys: ["message", "error", "reason"])
        return message.isEmpty ? fallback : message
    }

    private static func denialMessage(for statusCode: Int, payload: [String: Any]) -> String {
        let serverMessage = stringFromPayload(payload, keys: ["message", "error", "reason"])
        if !serverMessage.isEmpty { return serverMessage }
        switch statusCode {
        case 200...299:
            return "IP não liberado."
        case 400:
            return "O servidor não aceitou o IP informado."
        case 401, 403:
            return "IP não liberado."
        case 404:
            return "A rota de validação da chave não foi encontrada."
        case 429:
            return "Muitas tentativas. Aguarde e tente novamente."
        case 500...599:
            return "A API GBOX está indisponível no momento (HTTP \(statusCode)). Tente novamente mais tarde."
        default:
            return "A validação do IP foi recusada (HTTP \(statusCode))."
        }
    }

    private static func explicitlyDeniesAccess(
        payload: [String: Any],
        responseBody: Data
    ) -> Bool {
        for key in ["valid", "authorized", "allowed", "success", "ok"] {
            if let number = payload[key] as? NSNumber, number.intValue == 0 {
                return true
            }
            if let value = payload[key] as? String,
               ["false", "0", "no", "denied", "unauthorized", "invalid", "error", "blocked"].contains(value.lowercased()) {
                return true
            }
        }

        let status = stringFromPayload(payload, keys: ["status", "result"]).lowercased()
        if ["false", "denied", "unauthorized", "invalid", "error", "blocked", "rejected"].contains(status) {
            return true
        }

        guard let body = String(data: responseBody, encoding: .utf8)?.lowercased() else {
            return false
        }
        return [
            "unauthorized", "not authorized", "denied", "blocked", "invalid", "false", "error",
            "não autorizado", "nao autorizado", "não cadastrado", "nao cadastrado", "negado", "bloqueado", "inválido", "invalido", "falha"
        ].contains(where: body.contains)
    }

    private static func stringFromPayload(_ payload: [String: Any], keys: [String]) -> String {
        for key in keys {
            if let string = payload[key] as? String, !string.isEmpty {
                return string
            }
        }
        return ""
    }

    private func offlineMessage(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return "Sem conexão com a internet. Verifique sua rede."
            case .timedOut:
                return "Tempo esgotado ao conectar à API GBOX. Tente novamente."
            default:
                return "Não foi possível conectar à API GBOX: \(urlError.localizedDescription)"
            }
        }
        return (error as? LocalizedError)?.errorDescription ?? "Não foi possível conectar à API GBOX."
    }
}
