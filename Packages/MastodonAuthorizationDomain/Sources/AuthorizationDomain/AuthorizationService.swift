//
//  AuthorizationService.swift
//  MastodonAuthorizationDomain
//
//  Created by Nikita Prokhorchuk on 24.11.24.
//

import AuthenticationServices

public final class AuthorizationService {
    
    public init() {
    }
}

extension AuthorizationService {
    
    public func makeAuthorizationURL(instanceName name: String) -> URL {
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
    
    public func makeWebAuthenticationSession(url: URL) -> ASWebAuthenticationSession {
        ASWebAuthenticationSession(url: url, callbackURLScheme: Constants.callbackURLScheme) { callbackURL, error in
            guard
                error == nil,
                let callbackURL,
                let urlComponents = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                let code = urlComponents.queryItems?.first(where: { $0.name == "code" })?.value
            else {
                return
            }
            Task {
                let accessToken = try await ObtainTokenRequest(networkService: .api, code: code).response().accessToken
                try? Self.save(accessToken: accessToken)
            }
        }
    }
}

extension AuthorizationService {
    
    private static func save(accessToken: String) throws {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrAccount: "access_token",
            kSecAttrSynchronizable: false,
            kSecUseDataProtectionKeychain: true,
            kSecValueData: accessToken
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
    
    private static var accessToken: String? {
        get throws {
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrAccount: "access_token",
                kSecUseDataProtectionKeychain: true,
                kSecReturnData: true
            ] as NSDictionary
            
            var item: CFTypeRef?
            switch SecItemCopyMatching(query, &item) {
            case errSecSuccess:
                return item as? String
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
}
