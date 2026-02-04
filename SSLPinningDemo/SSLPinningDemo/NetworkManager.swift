//
//  NetworkManager.swift
//  SSLPinningDemo
//
//  Created by Neosoft on 22/01/26.
//

import Foundation
import CommonCrypto

class NetworkManager: NSObject {
    static let shared = NetworkManager()
   let localPublicKey = "UByNN6wh6WJFNj04mBWbj+iAfJP3C60LXpHBZXmMXwk="
    
    private let rsa2048Asn1Header:[UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00
    ]
    
    private func sha256(data: Data) -> String {
        var keyWithHeader = Data(rsa2048Asn1Header)
        keyWithHeader.append(data)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        keyWithHeader.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(keyWithHeader.count), &hash)
        }
        return Data(hash).base64EncodedString()
    }
    
    lazy var session: URLSession = { URLSession( configuration: .ephemeral, delegate: self, delegateQueue: nil)}()
    
        private override init() {
            super.init()
        }
    
    func request<T: Codable>(url: URL?, expected: T.Type, completion: @escaping (_ data: T?, _ error: Error?) -> ()) {
        
        guard let url else {
            print("Cannot form url")
            return
        }
        
        session.dataTask(with: url) { data, response, error in
            if let error {
                if error.localizedDescription == "cancelled" {
                    completion(nil, NSError.init(domain: "", code: -999, userInfo: [NSLocalizedDescriptionKey: "SSl pinning failed"]))
                    return
                }
                completion(nil, error)
                return
            }
            
            guard let data else {
                print("Something went wrong")
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let response = try decoder.decode(T.self, from: data)
                completion(response, nil)
            } catch {
                completion(nil, error)
            }
        }.resume()
        
    }
}
extension NetworkManager: URLSessionDelegate {
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        //Certificate pinning
        
        //Create a server trust
        guard let serverTrust = challenge.protectionSpace.serverTrust, let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
//        Public key pinning
        if let serverPublicKey = SecCertificateCopyKey(certificate), let serverPublicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) {
            
            let data: Data = serverPublicKeyData as Data
            let serverHashKey = sha256(data: data)
            
//            Comparing server and local hash key
            
            if serverHashKey == localPublicKey {

                print("Public key pinning is successfull")
//                completionHandler(.useCredential, credential)
            } else {
                print("Public Key pinning is failed")
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
        
        
        
        
        
        //SSL policy for domain check
        let policy = NSMutableArray()
        policy.add(SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString))
        
        //Evaluate the certificate
        let isServerTrust = SecTrustEvaluateWithError(serverTrust, nil)
        
        //Local and remote certificate data
        let remoteCertificateData: NSData = SecCertificateCopyData(certificate)
        let pathCertificate = Bundle.main.path(forResource: "openweathermap.org", ofType: "cer")
        let localCertificate: NSData = NSData.init(contentsOfFile: pathCertificate!)!
        
        if isServerTrust && remoteCertificateData.isEqual(to: localCertificate as Data) {
            let credential = URLCredential(trust: serverTrust)
            print("Certificate pinning is successfull")
            completionHandler(.useCredential, credential)
        } else {
            print("Certificate pinning is cancelled")
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
        
    }
}
