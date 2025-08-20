//
//  MainViewController.swift
//  test
//
//  Created by 黃盈雅 on 2025/8/5.
//

// 1995.06.16 ~ 至今

import UIKit

class MainViewController: UIViewController {
    
    @IBOutlet weak var lbInfo: UILabel!
    @IBOutlet weak var aivWait: UIActivityIndicatorView!
    @IBOutlet weak var imgNASA: UIImageView!
    @IBOutlet weak var pkvDate: UIPickerView!
    @IBOutlet weak var btnEnter: UIButton!

    // 年月日資料陣列
    var years: [Int] = []
    let months: [Int] = Array(1...12)
    var days: [Int] = []
        
    // 選取的年/月/日
    var selectedYear: Int?
    var selectedMonth: Int?
    var selectedDay: Int?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        aivWait.isHidden = true
            
        pkvDate.dataSource = self
        pkvDate.delegate = self
                
        setupYears()
                
        // 預設選擇為昨天
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        selectedYear = calendar.component(.year, from: yesterday)
        selectedMonth = calendar.component(.month, from: yesterday)
        selectedDay = calendar.component(.day, from: yesterday)
            
        updateDays()
                
        // 設定 picker 預設選擇
        if let yearIndex = years.firstIndex(of: selectedYear!),
            let monthIndex = months.firstIndex(of: selectedMonth!),
            let dayIndex = days.firstIndex(of: selectedDay!) {
            pkvDate.selectRow(yearIndex, inComponent: 0, animated: false)
            pkvDate.selectRow(monthIndex, inComponent: 1, animated: false)
            pkvDate.selectRow(dayIndex, inComponent: 2, animated: false)
        }
                
        btnEnter.addTarget(self, action: #selector(fetchButtonTapped), for: .touchUpInside)
        
        fetchData()
    }
        
    func setupYears() {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        years = Array((currentYear-20)...currentYear) // 過去 20 年到今年
    }
        
    func updateDays() {
        guard let year = selectedYear, let month = selectedMonth else {
            days = Array(1...31)
            return
        }
        
        var comps = DateComponents()
        comps.year = year
        comps.month = month
            
        let calendar = Calendar.current
        if let date = calendar.date(from: comps),
           let range = calendar.range(of: .day, in: .month, for: date) {
            days = Array(range)
        } else {
            days = Array(1...31)
        }
        
        // 如果目前選的 day 大於最大天數，調整為最大天
        if let day = selectedDay, day > days.count {
            selectedDay = days.last
        }
    }
        
    @IBAction func fetchButtonTapped(_ sender: UIButton) {
        fetchData()
    }
    
    func fetchData() {
        guard let year = selectedYear,
              let month = selectedMonth,
              let day = selectedDay else { return }
        
        let dateString = String(format: "%04d-%02d-%02d", year, month, day)
        print("Fetch NASA data for date: \(dateString)")
        
        // 顯示等待動畫
        lbInfo.text = "讀取中..."
        aivWait.isHidden = false
        aivWait.startAnimating()
        imgNASA.image = nil
        
        NetworkManager.shared.fetchNASAData(for: dateString) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch result {
                case .success(let nasaData):
                    // 更新文字
                    self.lbInfo.text = "\(nasaData.date)\n\(nasaData.title)"
                    
                    // 下載圖片 → 設定到 UIImageView → 停止動畫
                    self.loadImage(from: nasaData.url) { image in
                        self.imgNASA.image = image
                        self.aivWait.stopAnimating()
                        self.aivWait.isHidden = true
                    }
                    
                case .failure(let error):
                    self.lbInfo.text = "讀取失敗：\(error.localizedDescription)"
                    self.aivWait.stopAnimating()
                    self.aivWait.isHidden = true
                }
            }
        }
    }
    
    func loadImage(from urlString: String,
                   completion: @escaping (UIImage?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("URL 格式錯誤")
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error = error {
                print("下載圖片失敗: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                print("圖片資料為空或無法轉換成 UIImage")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // 成功下載，回傳圖片
            DispatchQueue.main.async {
                completion(image)
            }
        }.resume()
    }

}

extension MainViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3 // 年、月、日三欄
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch component {
        case 0: return years.count
        case 1: return months.count
        case 2: return days.count
        default: return 0
        }
    }
}

// MARK: - UIPickerViewDelegate
extension MainViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        // 三欄平均寬度，可依需求調整
        return pickerView.bounds.width / 3 - 10
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0: return "\(years[row])"
        case 1: return "\(months[row])"
        case 2: return "\(days[row])"
        default: return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch component {
        case 0:
            selectedYear = years[row]
            updateDays()
            pkvDate.reloadComponent(2) // 重新載入日欄，因為天數可能變動
            
            // 確保日欄不會超出範圍
            if let day = selectedDay,
               let dayIndex = days.firstIndex(of: day) {
                pkvDate.selectRow(dayIndex, inComponent: 2, animated: true)
            } else {
                selectedDay = days.first
                pkvDate.selectRow(0, inComponent: 2, animated: true)
            }
        case 1:
            selectedMonth = months[row]
            updateDays()
            pkvDate.reloadComponent(2)
            if let day = selectedDay,
               let dayIndex = days.firstIndex(of: day) {
                pkvDate.selectRow(dayIndex, inComponent: 2, animated: true)
            } else {
                selectedDay = days.first
                pkvDate.selectRow(0, inComponent: 2, animated: true)
            }
        case 2:
            selectedDay = days[row]
        default:
            break
        }
    }
}


