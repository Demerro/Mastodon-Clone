//
//  AuthorizationService.swift
//  MastodonAuthorizationDomain
//
//  Created by Nikita Prokhorchuk on 24.11.24.
//

import AuthenticationServices

@MainActor
public final class AuthorizationService {
    
    private init() {
    }
}

extension AuthorizationService {
    
    public static var isAuthorized: Bool {
        UserDefaults.standard.string(forKey: "instance_name")
            .map {
                try? AuthorizationService.getAccessToken(for: $0)
            } != nil
    }
    
    public static func makeAuthorizationURL(instanceName name: String) -> URL {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = name
        urlComponents.path = "/oauth/authorize"
        urlComponents.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: Constants.clientKey),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "scope", value: Constants.scopes),
            URLQueryItem(name: "lang", value: Locale.current.languageCode),
        ]
        return urlComponents.url!
    }
    
    public static func makeWebAuthenticationSession(url: URL, completion: (() -> Void)? = nil) -> ASWebAuthenticationSession {
        ASWebAuthenticationSession(url: url, callbackURLScheme: Constants.callbackURLScheme) { callbackURL, error in
            guard
                error == nil,
                let callbackURL,
                let instanceHost = url.host,
                let urlComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                let code = urlComponents.queryItems?.first(where: { $0.name == "code" })?.value
            else {
                return
            }
            Task {
                let accessToken = try await ObtainTokenRequest(networkService: .api, instanceHost: instanceHost, code: code).response().accessToken
                try? Self.saveAccessToken(accessToken, for: instanceHost)
                UserDefaults.standard.set(instanceHost, forKey: "instance_name")
                completion?()
            }
        }
    }
}

extension AuthorizationService {
    
    private static func saveAccessToken(_ accessToken: String, for instanceHost: String) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccount: instanceHost,
            kSecAttrSynchronizable: false,
            kSecUseDataProtectionKeychain: true,
            kSecValueData: accessToken.data(using: .utf8)!
        ] as NSDictionary
        
        let status = SecItemAdd(query, nil)
        if status != errSecSuccess {
            throw NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: SecCopyErrorMessageString(status, nil) ?? ""]
            )
        }
    }
    
    public static func getAccessToken(for instanceHost: String) throws -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: instanceHost,
            kSecUseDataProtectionKeychain: true,
            kSecReturnData: true
        ] as NSDictionary
        
        var item: CFTypeRef?
        switch SecItemCopyMatching(query, &item) {
        case errSecSuccess:
            return String(data: item as! Data, encoding: .utf8)
        case errSecItemNotFound:
            return nil
        case let status:
            throw NSError(
                domain: NSOSStatusErrorDomain,
                code: Int(status),
                userInfo: [NSLocalizedDescriptionKey: SecCopyErrorMessageString(status, nil) ?? ""]
            )
        }
    }
}

extension AuthorizationService {
    
    public static var instanceName: String? {
        UserDefaults.standard.string(forKey: "instance_name")
    }
}
