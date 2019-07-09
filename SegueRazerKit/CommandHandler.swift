//
//  CommandLineDescription.swift
//  SegueRazer
//
//  Created by szotp on 07/07/2019.
//  Copyright © 2019 szotp. All rights reserved.
//

import Foundation


private protocol AnyArg {
    func setup(name: String, value: String?) throws
}

struct ParsingError: Error {
    var message: String
}

/// Will become @propertyWrapper
public class Arg<T>: AnyArg, CustomStringConvertible {
    let helper: String
    let defaultValue: T?
    
    init(helper: String, defaultValue: T? = nil) {
        self.helper = helper
        self.defaultValue = defaultValue
    }
    
    public var description: String {
        var additional = "\(T.self)"
        if let defaultValue = defaultValue {
            additional += ", default: \(defaultValue)"
        }
        
        return "\(helper) (\(additional))"
    }
    
    var innerValue: T!
    
    public var value: T {
        get {
            return innerValue ?? defaultValue!
        }
        set {
            innerValue = newValue
        }
    }
    
    func parse(value: String) -> Any? {
        switch T.self {
        case let type as LosslessStringConvertible.Type:
            return type.init(value)
        case let type as URL.Type:
            return type.init(string: value)
        default:
            return nil
        }
    }
    
    func setup(name: String, value: String?) throws {
        if let value = value {
            let parsed = parse(value: value) as? T
            if parsed == nil {
                throw ParsingError(message: "Failed to parse -\(name) \(value)")
            }
            self.innerValue = parsed
        } else if let defaultValue = defaultValue {
            self.innerValue = defaultValue
        } else if let asNil = T.self as? ExpressibleByNilLiteral.Type {
            self.innerValue = asNil.init(nilLiteral: ()) as? T
        } else {
            throw ParsingError(message: "Missing parameter: \(name)")
        }
    }
}

public struct CommandHandler {
    var command: CommandProtocol
    
    public init(_ command: CommandProtocol) {
        self.command = command
    }
    
    private func parseArgumentsIntoDictionary() -> [String: String] {
        let args = ProcessInfo.processInfo.arguments
        var dict: [String: String] = [:]
        
        var i = 0
        while i < args.count {
            let current = args[i]
            if current.starts(with: "-") {
                let b = current.index(after: current.startIndex)
                let key = String(current[b...])
                dict[key] = args[i + 1]
                i += 2
            } else {
                i += 1
            }
        }
        return dict
    }
    
    func printError(error: String) {
        
    }
    
    private func enumerateArgs(block: (String, AnyArg) throws -> Void) rethrows {
        for (name, value) in Mirror(reflecting: command).children {
            if let arg = value as? AnyArg {
                try block(name!, arg)
            }
        }
    }
    
    func parse() throws {
        let dict = parseArgumentsIntoDictionary()
        
        try enumerateArgs { (name, arg) in
            try arg.setup(name: name, value: dict[name])
        }
        
        try command.validate()
        
    }
    
    func printHelp() {
        print("\(type(of:command))")
        print(command.helper)
        
        enumerateArgs { (name, arg) in
            let padded = name.padding(toLength: 30, withPad: " ", startingAt: 0)
            print("  -\(padded)\(arg)")
        }
    }
    
    public func parseAndRun() {
        do {
            try parse()
            command.execute()
            print("done")
        } catch let error as ParsingError {
            print("error: " + error.message)
            print()
            printHelp()
        } catch {
            assertionFailure()
        }
    }
}

public protocol CommandProtocol {
    var helper: String {get}
    func validate() throws
    func execute()
}
