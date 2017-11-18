//
//  DOPFileInspectorController.swift
//  DOPFileInspector
//
//  Created by 纬洲 冯 on 17/11/2017.
//  Copyright © 2017 fengweizhou. All rights reserved.
//

import UIKit
import MobileCoreServices

class DOPFileInspectorController: UITableViewController {
    
    let backgroundLabel = UILabel()
    var subDirs = [String]()
    var files = [String]()
    let path: String
    
    init(path: String) {
        self.path = path
        super.init(style: .plain)
    }
    
    convenience init() {
        self.init(path: NSHomeDirectory())
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        super.loadView()
        self.title = URL(string:self.path)?.lastPathComponent
        backgroundLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        backgroundLabel.textColor = UIColor.darkGray
        backgroundLabel.textAlignment = .center
        backgroundLabel.numberOfLines = 0
        tableView.backgroundView = backgroundLabel
        tableView.tableFooterView = UIView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: path) {
            for element in contents {
                let fullPath = path + "/" + element
                if FileManager.default.isReadableFile(atPath: fullPath) {
                    var isDir: ObjCBool = false
                    FileManager.default.fileExists(atPath: fullPath, isDirectory: &isDir)
                    if isDir.boolValue {
                        subDirs.append(element)
                    } else {
                        files.append(element)
                    }
                }
            }
            
            subDirs.sort()
            files.sort()
            
            refreshBackgroundLabel()
        }
    }
}

extension DOPFileInspectorController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return subDirs.count
        case 1: return files.count
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel!.adjustsFontSizeToFitWidth = true
        switch indexPath.section {
        case 0:
            cell.textLabel!.text = subDirs[indexPath.row]
            cell.accessoryType = .disclosureIndicator
        case 1:
            cell.textLabel!.text = files[indexPath.row]
            cell.accessoryType = .none
        default:
            cell.textLabel!.text = ""
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 0:
            let fullPath = path + "/" + subDirs[indexPath.row]
            let vc = DOPFileInspectorController(path: fullPath)
            navigationController?.show(vc, sender: nil)
        case 1:
            let fullPath = path + "/" + files[indexPath.row]
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let action1 = UIAlertAction(title: "Share By AirDrop", style: .default, handler: { (action) in
                self.shareByAirdrop(at: fullPath)
            })
            actionSheet.addAction(action1)
//            let action2 = UIAlertAction(title: "Share By Upload", style: .default, handler: { (action) in
//                self.shareByUpload(at: fullPath)
//            })
//            actionSheet.addAction(action2)
            let cancel = UIAlertAction(title: "cancel", style: .cancel, handler: nil)
            actionSheet.addAction(cancel)
            present(actionSheet, animated: true, completion: nil)
        default:
            fatalError()
        }
    }
}

extension DOPFileInspectorController {
    func refreshBackgroundLabel() {
        backgroundLabel.text = subDirs.count + files.count > 0 ? "" : "This directory is empty"
    }
    
    func shareByAirdrop(at path: String) {
        let fileURL = URL(fileURLWithPath: path)
        let activity = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        activity.excludedActivityTypes = [.postToTwitter, .postToVimeo, .postToWeibo, .postToFlickr, .postToFacebook, .postToTencentWeibo, .copyToPasteboard, .addToReadingList, .assignToContact, .mail, .markupAsPDF, .message, .openInIBooks, .print, .saveToCameraRoll]
        present(activity, animated: true, completion: nil)
    }
    
    func shareByUpload(at path: String) {
        let boundary = "Ju5tH77P15Aw350m3"
        if let url = URL(string: "http://192.168.0.106:3000/log/upload") {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            req.httpBody = createBody(filePath: path, boundary: boundary)
            let task = URLSession.shared.uploadTask(with: req, fromFile: URL(fileURLWithPath: path)) { (data, res, error) in
                if let theError = error {
                    print(theError)
                } else {
                    let ac = UIAlertController(title: "Upload Success", message: nil, preferredStyle: .alert)
                    let action = UIAlertAction(title: "Ok", style: .default, handler: nil)
                    ac.addAction(action)
                    self.present(ac, animated: true, completion: nil)
                }
            }
            task.resume()
        }
        
    }
    
    func createBody(filePath: String, boundary: String) -> Data {
        var body = Data()
        let url = URL(fileURLWithPath: filePath)
        let filename = url.lastPathComponent
        let mimetype = mimeType(for: path)
        if let data = try? Data(contentsOf: url) {
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"log\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(mimetype)\r\n\r\n")
            body.append(data)
            body.append("\r\n")
            body.append("--\(boundary)--\r\n")
        }
        return body
    }
    
    func mimeType(for path: String) -> String {
        let url = NSURL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension! as NSString, nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream";
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
