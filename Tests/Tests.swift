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
    var shouldTryToBuild = true
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testTestProjects() {
        let fm = FileManager.default
        let testProjectsURL = ProjectDirectory.get().appendingPathComponent("TestProjects")
        assert(fm.fileExists(atPath: testProjectsURL.path))
        
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("SegueRazer")
        try? fm.removeItem(at: url)
        try! fm.copyItem(at: testProjectsURL, to: url)
        
        for dir in try! fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: []) {
            let path = dir.path
            if dir.isHidden {
                continue
            }
            
            print("RUNNING: " + path)
            let tool = SegueRazer()
            tool.projectURL.value = dir
            tool.execute()
            
            if shouldTryToBuild {
                let code = shell(launchPath: "/usr/bin/xcodebuild", "CODE_SIGNING_ALLOWED=NO")
                XCTAssertEqual(code, 0)
            }
            
            print("ok")
        }
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
