//
//  Tests.swift
//  Tests
//
//  Created by szotp on 20/07/2018.
//  Copyright © 2018 szotp. All rights reserved.
//

import XCTest
import SegueRazerKit

class Tests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testConvertTestProject() {
        let fm = FileManager.default
        let originalURL = ProjectDirectory.get().appendingPathComponent("TestProjects").appendingPathComponent("Simple")
        let convertedURL = originalURL.renamed(newName: "SimpleConverted")
        
        assert(fm.fileExists(atPath: originalURL.path))
        try? fm.removeItem(at: convertedURL)
        try! fm.copyItem(at: originalURL, to: convertedURL)
        
        print("RUNNING: " + originalURL.path)
        let tool = SegueRazer()
        tool.projectURL.value = convertedURL
        tool.execute()
        
        let code = shell(launchPath: "/usr/bin/xcodebuild", "CODE_SIGNING_ALLOWED=NO")
        XCTAssertEqual(code, 0)
    }
}

extension URL {
    func renamed(newName: String) -> URL {
        assert(isFileURL)
        return deletingLastPathComponent().appendingPathComponent(newName)
    }
}

private extension URL {
    var isHidden: Bool {
        get {
            return (try? resourceValues(forKeys: [.isHiddenKey]))?.isHidden == true
        }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.isHidden = newValue
            do {
                try setResourceValues(resourceValues)
            } catch {
                print("isHidden error:", error)
            }
        }
    }
}
