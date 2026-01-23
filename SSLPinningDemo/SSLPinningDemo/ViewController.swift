//
//  ViewController.swift
//  SSLPinningDemo
//
//  Created by Neosoft on 22/01/26.
//

import UIKit

struct WeatherResponse: Codable {
    let main: Main
    struct Main: Codable {
        let tempMin: Double
        let tempMax: Double
    }
}
//struct Product: Codable{
//    var rating: Rating
//    
//    struct Rating: Codable {
//        var rate: Float
//        var count: Int
//    }
//}

class ViewController: UIViewController {
    
    @IBOutlet weak var tempMaxLabel: UILabel!
    @IBOutlet weak var tempMinLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    
    @IBAction func tapButtonAction(_ sender: Any) {
        request()
    }
    
    func request(){
        
        var url = URL.init(string: "https://api.openweathermap.org/data/2.5/weather")

        url?.append(queryItems: [
            URLQueryItem(name: "lat", value: "34.8640"),
            URLQueryItem(name: "lon", value: "84.3241"),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "appid", value: "26f1ffa29736dc1105d00b93743954d2")
        ])
        
//        var url = URL.init(string: "https://fakestoreapi.com/products")
        
        NetworkManager.shared.request(url: url, expected: WeatherResponse.self) { [weak self] data, error in
            
            if let error {
                print(error.localizedDescription)
                return
            }
            
            if let data {
                DispatchQueue.main.async {
                    self?.tempMaxLabel.text = "\(data.main.tempMax)"
                    self?.tempMinLabel.text = "\(data.main.tempMin)"
                }
            }
        }
    }

}

