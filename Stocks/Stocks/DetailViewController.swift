//
//  DetailViewController.swift
//  Stocks
//
//  Created by Влад Комсомоленко on 05.09.2021.
//

import UIKit

class DetailViewController: UIViewController {

    // MARK: - private properties
    
    var name: String = ""
    var symbol: String = ""
    private var stocks = [Double]()
    @IBOutlet weak var companyName: UILabel!
    
    // MARK: - Private methods
    
    private func requestQuote(for symbol: String) {

        let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/chart/1y?token=pk_430e716f596347ff82b2b7bb29683e68")!
        
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                error == nil,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let data = data
            else {
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "❗Network error", message: "\(error?.localizedDescription ?? "Error!")", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
                    self.present(alert, animated: true, completion: nil)
                }
                print("❗Network error")
                return
            }
            self.parseQuote(data: data)
        }
        
        dataTask.resume()
    }
    
    private func parseQuote(data: Data) {
        do {
            let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            
            for object in jsonObject ?? [] {
                guard
                    let json = object as? [String: Any],
                    let stock = json["open"] as? Double
                else {
                    print("❗Invalid JSON format")
                    return
                }
                self.stocks.append(stock)
            }
        } catch {
            print("❗JSON parsing error: " + error.localizedDescription)
        }
        DispatchQueue.main.async {
            self.label.text = "\(self.stocks)"
        }
    }
    
    // MARK: - View lifecycle
    
    @IBOutlet weak var label: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        companyName.text = name
        self.requestQuote(for: self.symbol)
        // label.text = "\(self.stocks)"
    }

}
