//
//  ViewController.swift
//  tinkoffCourses
//
//  Created by Михаил on 30.08.2020.
//  Copyright © 2020 Михаил. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var companySymbolLabel: UILabel!
    
    @IBOutlet weak var priceLabel: UILabel!
    
    @IBOutlet weak var priceChangeLabel: UILabel!
    
    @IBOutlet weak var stockLogo: UIImageView!
    
    let token = "pk_82b3acb33f8e4a3fb4801fbb607b0807"
    
    var apiCompanies = [String:String]()
    
    
     private var animateFlag = false
    
    
    private lazy var companies = [
        "Apple":"AAPL",
        "Microsoft":"MSFT",
        "Google":"GOOG",
        "Amazon":"AMZN",
        "Facebook":"FB"
    ]
    
    
    
    private func parseImage(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let imageURL = json["url"] as? String else {return print("JSON trouble")}
            
            
            guard
                let url = URL(string: imageURL),
                let data = try? Data(contentsOf: url),
                let logo = UIImage(data: data) else {return print("Broken logo")}
            
                DispatchQueue.main.async { [weak self] in
                    self?.setLogo(image: logo)
                }

            
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
        }
    }

    
    
    private func setLogo(image: UIImage) {
        stockLogo.image = image
        if animateFlag {
            animateFlag = false
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    private func parseQuote(from data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double else { return print("Invalid JSON") }
            
            DispatchQueue.main.async { [weak self] in
                self?.displayStockInfo(companyName: companyName,
                                       companySymbol: companySymbol,
                                       price: price,
                                       priceChange: priceChange)
            }
        } catch {
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    
    private func errorMessage() {
        companyPickerView.reloadAllComponents()
        let alert = UIAlertController(title: "Error", message: "Problem with Internet Connection", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    
    
    //Отображаем Информацию об акциях
    private func displayStockInfo(companyName: String,
                                  companySymbol: String,
                                  price: Double,
                                  priceChange: Double) {
    activityIndicator.stopAnimating()
    companyNameLabel.text = companyName
    companySymbolLabel.text = companySymbol
    priceLabel.text = "\(price)"
    priceChangeLabel.text = "\(priceChange)"
    priceChangeLabel.textColor = priceChange > 0 ? UIColor.green : UIColor.red
    }
        
    
    
    
    
    
    
    
    
//    get запрос
    
    
    private func requestQuote(for symbol: String) {        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)") else {
            return
        }
        
        guard let imageUrl = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?token=\(token)") else {
                   return
               }
        
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data,
            (response as? HTTPURLResponse)?.statusCode == 200,
            error == nil {
                self.parseQuote(from: data)
            }else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage()
                }}
        }
        
        
        
        
        let dataTaskForImage = URLSession.shared.dataTask(with: imageUrl) { [weak self] (data, response, error) in
            if let data = data,
            (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                self?.parseImage(from: data)
            }else {
            DispatchQueue.main.async { [weak self] in
                self?.errorMessage()
                }}
            }
        
        
        dataTaskForImage.resume()
        dataTask.resume()
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        companyNameLabel.text = "Tinkoff"
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        
        activityIndicator.startAnimating()
        requestQuoteUpdate()
        
    }
    
    private func requestQuoteUpdate() {
        activityIndicator.startAnimating()
        
        companyNameLabel.text = "-"
        companySymbolLabel.text = "-"
        priceLabel.text = "-"
        priceChangeLabel.text = "-"
        priceChangeLabel.textColor = UIColor.black
        
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        requestQuote(for: selectedSymbol)
    }
    
    
    
    
}

extension ViewController : UIPickerViewDataSource{
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companies.keys.count
    }
        
}

extension ViewController : UIPickerViewDelegate{
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(companies.keys)[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        requestQuoteUpdate()
    }
    
}
