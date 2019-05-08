//
//  Logger.swift
//  HealthRecordsSampleApp
//
//  Created by Vijay Godse on 5/8/19.
//

import Foundation

final class Logger: TextOutputStream {
    
    static let shared = Logger()
    
    private init() {}
    
    func write(_ string: String) {
        print(string)
        let fm = FileManager.default
        let log = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("log.txt")
        if let handle = try? FileHandle(forWritingTo: log) {
            handle.seekToEndOfFile()
            let newLineStr = "\n"
            handle.write(newLineStr.data(using: .utf8)!)
            handle.write(string.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? string.data(using: .utf8)?.write(to: log)
        }
    }
}
