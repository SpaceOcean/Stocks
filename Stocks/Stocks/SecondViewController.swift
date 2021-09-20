//
//  SecondViewController.swift
//  Stocks
//
//  Created by Влад Комсомоленко on 04.09.2021.
//

import UIKit

class SecondViewController: UITableViewController {
    
    // MARK: - private properties
    
    struct Company {
        let companyName, companySymbol: String
        let price, priceChange: Double
        let imgUrl: String?
    }
    private var companies = [Company]()

    
    // MARK: - Private methods Img
   
    private func requestImg(for symbol: String, companyName: String, price: Double, priceChange: Double) {

        let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?token=pk_430e716f596347ff82b2b7bb29683e68")!
        
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
            var imgUrl = self.parseImg(data: data)
            if imgUrl == "" {
                imgUrl = "https://ae01.alicdn.com/kf/Ue21a37ec0cb246029a786c0b05cdad851/Lamp-Minecraft-Alex-icon-light-BDP-pp6591mcf.png"
            }
            self.companies.append(Company(companyName: companyName, companySymbol: symbol, price: price, priceChange: priceChange, imgUrl: imgUrl))
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        dataTask.resume()
        
    }
    
    private func parseImg(data: Data) -> String? {
        do {
            let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                
            guard
                let json = jsonObject as? [String: Any],
                let companyImg = json["url"] as? String
            else {
                print("❗Invalid JSON format")
                return nil
            }
            return companyImg

        } catch {
            print("❗JSON parsing error: " + error.localizedDescription)
        }
        
    }
    
    // MARK: - Private methods Quote
    
    private func requestQuote(type: String) {
        self.companies.removeAll()
        let url = URL(string: "https://cloud.iexapis.com/stable/stock/market/list/\(type)?token=pk_430e716f596347ff82b2b7bb29683e68")!
        
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
                    let companyName = json["companyName"] as? String,
                    let companySymbol = json["symbol"] as? String,
                    let price = json["latestPrice"] as? Double,
                    let priceChange = json["change"] as? Double
                else {
                    print("❗Invalid JSON format")
                    return
                }
                
                self.requestImg(for: companySymbol, companyName: companyName, price: price, priceChange: priceChange)
            }
        } catch {
            print("❗JSON parsing error: " + error.localizedDescription)
        }
        
    }
    
    // MARK: - segmentedControl
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBAction func choiceSegment(_ sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            self.requestQuote(type: "mostactive")
        case 1:
            self.requestQuote(type: "gainers")
        case 2:
            self.requestQuote(type: "losers")
        case 3:
            self.requestQuote(type: "iexvolume")
        case 4:
            self.requestQuote(type: "iexpercent")
        default:
            print("❗segmentedControl error")
        }
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.requestQuote(type: "mostactive")
        
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return self.companies.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "stockCell", for: indexPath) as! CustomTableViewCell
        
        // add image
        let urlString = self.companies[indexPath.row].imgUrl
        
        let url = NSURL(string: urlString ?? "")! as URL
        if let imageData: NSData = NSData(contentsOf: url) {
            cell.companyImg.image =  UIImage(data: imageData as Data)
        }
        
        // add info
        cell.companyName.text = self.companies[indexPath.row].companyName
        cell.companySymbol.text = self.companies[indexPath.row].companySymbol
        cell.price.text = "\(self.companies[indexPath.row].price) $"
        cell.priceChange.text = "\(self.companies[indexPath.row].priceChange)"
        
        // change color of priceChange
        if (self.companies[indexPath.row].priceChange > 0) {
            cell.priceChange.textColor = UIColor.green
        } else if (self.companies[indexPath.row].priceChange < 0) {
            cell.priceChange.textColor = UIColor.red
        }
        return cell
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "detailSegue" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let dvc = segue.destination as! DetailViewController
                dvc.name = self.companies[indexPath.row].companyName
                dvc.symbol = self.companies[indexPath.row].companySymbol
            }
        }
    }
}

