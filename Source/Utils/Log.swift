//
//  Log.swift
//  VirgilSDK
//
//  Created by Oleksandr Deundiak on 8/23/17.
//  Copyright © 2017 VirgilSecurity. All rights reserved.
//

import Foundation

internal class Log {
    internal class func debug(_ closure: @autoclosure () -> String, functionName: String = #function,
                              file: String = #file, line: UInt = #line) {
        #if DEBUG
            self.log("<DEBUG>: \(closure())", functionName: functionName, file: file, line: line)
        #endif
    }

    internal class func error( _ closure: @autoclosure () -> String, functionName: String = #function,
                               file: String = #file, line: UInt = #line) {
        self.log("<ERROR>: \(closure())", functionName: functionName, file: file, line: line)
    }

    private class func log(_ closure: @autoclosure () -> String, functionName: String = #function,
                           file: String = #file, line: UInt = #line) {
        let str = "VIRGILSDK_LOG: \(functionName) : \(closure())"
        Log.writeInLog(str)
    }

    private class func writeInLog(_ message: String) {
        NSLogv("%@", getVaList([message]))
    }
}
