//
//  DebuggingEncodable.swift
//  SegueRazerKit
//
//  Created by szotp on 07/07/2019.
//  Copyright © 2019 szotp. All rights reserved.
//

import Foundation

struct DebuggingEncodable: Encodable {
    var value: Any
    
    func encode(to encoder: Encoder) throws {
        struct StringCodingKey: CodingKey {
            var stringValue: String
            
            init?(intValue: Int) {
                fatalError()
            }
            
            init?(stringValue: String) {
                self.stringValue = stringValue
            }
            
            var intValue: Int? {
                fatalError()
            }
        }
        
        struct AnyEncodable: Encodable {
            var value: Any
            func encode(to encoder: Encoder) throws {
                func encodeString(_ value: String) {
                    var container = encoder.singleValueContainer()
                    try! container.encode("\(value)")
                }
                
                switch value {
                case let x as URL:
                    encodeString(x.path)
                    
                case let x as Encodable:
                    try x.encode(to: encoder)
                    
                case let array as [NodeBase]:
                    let mapped = array.map(DebuggingEncodable.init)
                    try mapped.encode(to: encoder)
                    
                case is NodeBase:
                    try DebuggingEncodable(value: value).encode(to: encoder)
                    
                case is XMLNode:
                    encodeString("<\(type(of:value))>")
                default:
                    encodeString("\(value)")
                }
            }
        }
        
        var container = encoder.container(keyedBy: StringCodingKey.self)
        var mirrors = [Mirror(reflecting: value)]
        
        while let mirror = mirrors.last?.superclassMirror {
            mirrors.append(mirror)
        }
        
        for mirror in mirrors.reversed() {
            for (name, value) in mirror.children{
                if name == "parent" {
                    continue
                }
                
                try container.encode(
                    AnyEncodable(value: value),
                    forKey: StringCodingKey(stringValue: name!)!
                )
            }
        }
    }
}
