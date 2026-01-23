//
//  NetworkManager.swift
//  SSLPinningDemo
//
//  Created by Neosoft on 22/01/26.
//

import Foundation

class NetworkManager: NSObject {
    static let shared = NetworkManager()
    
    lazy var session: URLSession = { URLSession( configuration: .ephemeral, delegate: nil, delegateQueue: nil)}()

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
