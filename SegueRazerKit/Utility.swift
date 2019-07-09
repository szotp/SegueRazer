//
//  Utility.swift
//  SegueRazer
//
//  Created by szotp on 10/05/2018.
//  Copyright © 2018 szotp. All rights reserved.
//

import Foundation
import SwiftShell

class SourceWriter {
    class ExtensionBookmark {
        let name: String
        
        init(name: String) {
            self.name = name
        }
        
        var content = ""
    }
    
    var header = ""
    var currentExtension: ExtensionBookmark?
    
    var allExtensions: [ExtensionBookmark] = []
    
    let url: URL
    
    init(path: String) {
        self.url = URL(fileURLWithPath: path)
    }
    
    var indentation: Int = 0
    func append(_ line: String) {
        var padding = ""
        
        for _ in 0..<indentation {
            padding += "  "
        }
        
        var decoratedLine = ""
        
        decoratedLine += padding
        decoratedLine += line
        decoratedLine += "\n"
        
        if let current = currentExtension {
            current.content += decoratedLine
        } else {
            header += decoratedLine
        }
    }
    
    func begin() {
        indentation += 1
    }
    
    func end() {
        indentation -= 1
    }
    
    func appendComments(_ comments: String) {
        let lines = comments.split(separator: "\n")
        for line in lines {
            append("//\(line)")
        }
    }
    
    func beginExtension(name: String) {
        if name == currentExtension?.name {
            append("")
            return
        }
        
        currentExtension = ExtensionBookmark(name: name)
        append("extension \(name) {")
        indentation += 1
    }
    
    func endExtension() {
        assert(indentation == 1)
        
        indentation -= 1
        append("}")
        append("")
        
        if let previous = currentExtension {
            allExtensions.append(previous)
        }
        currentExtension = nil
    }
    
    func findViewControllers() -> [String: URL] {
        var dict: [String: URL] = [:]
        let enumerator = FileManager.default.enumerator(at: URL(fileURLWithPath: "."), includingPropertiesForKeys: nil)!
        
        for file in enumerator {
            let url = file as! URL
            if url.lastPathComponent.hasSuffix("ViewController.swift") {
                var name = url.lastPathComponent
                name.removeSubrange(name.index(name.endIndex, offsetBy: -6)...)
                dict[name] = url
            }
        }
        
        return dict
    }
    
    func save() {
        var content = ""
        content.append(header)
        
        let vcs = findViewControllers()
        
        for ext in allExtensions {
            if let url = vcs[ext.name] {
                var source = try! String(contentsOf: url)
                source += "\n"
                source += ext.content
                try! source.write(to: url, atomically: false, encoding: .utf8)
            } else {
                content.append(ext.content)
            }
        }
        
        try! content.write(to: url, atomically: false, encoding: .utf8)
    }
    
    private var usedIdentifiers: Set<String> = []
    
    func makeUnique(_ input: String, context: String? = nil) -> String {
        var i = 0
        var newIdentifier = input
        
        while usedIdentifiers.contains(newIdentifier) {
            newIdentifier = input + String(i)
            i += 1
        }
        
        usedIdentifiers.insert(newIdentifier)
        return newIdentifier
    }

}

extension Optional {
    struct NilOptionalError: Error {
        
    }
    
    func get() throws -> Wrapped {
        if let value = self {
            return value
        } else {
            throw NilOptionalError()
        }
    }
}

extension String {
    func capitalizedCharacter(at index: Int) -> String {
        let name = self
        let start = name.startIndex
        let middle = name.index(start, offsetBy: index)
        let afterMiddle = name.index(after: middle)
        
        return String(name[..<middle]) + String(name[middle...middle]).capitalized + String(name[afterMiddle...])
    }
    
    func indent(_ length: Int) -> String {
        let prefix = "".padding(toLength: length, withPad: " ", startingAt: 0)
        
        var lines = split(separator: "\n")
        for i in 1..<lines.count {
            lines[i] = prefix + lines[i]
        }
        return lines.joined(separator: "\n")
    }
}

func logWarning(_ text: String) {
    print("WARNING: \(text)")
}


@discardableResult
public func shell(launchPath: String = "/usr/bin/env", _ args: String...) -> Int {
    let result = run(launchPath, args)
    
    if !result.succeeded {
        print(result.stdout)
        print(result.stderror)
    }
    
    return result.exitcode
}

extension XMLElement {
    func setAttribute(name: String, value: String) {
        let newAttribute = XMLElement(kind: .attribute)
        newAttribute.name = name
        newAttribute.stringValue = value
        addAttribute(newAttribute)
    }
    
    func getAttribute(_ name: String) -> String? {
        return attribute(forName: name)?.stringValue
    }
    
    func removeFromParent() {
        let parent = self.parent as! XMLElement
        let index = parent.children!.index(of: self)!
        parent.removeChild(at: index)
    }
}
