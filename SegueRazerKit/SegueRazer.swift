//
//  SegueConverter.swift
//  SegueRazer
//
//  Created by szotp on 11/05/2018.
//  Copyright © 2018 szotp. All rights reserved.
//

import Foundation
import xcodeproj
import PathKit

public struct SegueRazer: CommandProtocol {
    public init() {}
    
    public var helper: String {
        return "Razes navigation segues from storyboards and replaces them with explicit instantiation."
    }
    
    public let projectURL = Arg<URL>(
        helper: "Path to directory containing xcode proj"
    )
    
    public let shouldAddFilesToXcodeProj = Arg<Bool>(
        helper: "Should attempt to edit xcodeproj?",
        defaultValue: true
    )
    
    public let reset = Arg<Bool>(
        helper: "(DANGER) Resets git state to latest commit. Useful for testing.",
        defaultValue: false
    )
    
    public func validate() throws {
        if !FileManager.default.fileExists(atPath: projectURL.value.path) {
            throw ParsingError(message: "Project does not exist")
        }
    }
    
    public func execute() {
        let projectURL = self.projectURL.value
        
        FileManager.default.changeCurrentDirectoryPath(projectURL.path)
        if reset.value {
            shell("git", "reset", "--hard")
            shell("git", "clean", "-f", "-d")
            shell("git", "status")
        }

        
        let converter = SegueConverter(projectURL: projectURL)
        converter.SegueRazers()
        
        if shouldAddFilesToXcodeProj.value {
            addFilesToXcodeProj()
        }
    }
    
    func addFilesToXcodeProj() {
        let dir = projectURL.value
        let fm = FileManager.default
        let projectContents = try! fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil, options: [])
        let xcodeproj = projectContents.first { (url) -> Bool in
            url.pathExtension == "xcodeproj"
            }!
        
        let root = Path(dir.path)
        
        let proj = try! XcodeProj(path: Path(xcodeproj.path))
        
        let projObject = proj.pbxproj.projects.first!
        
        func addFile(name: String) throws {
            let file = try projObject.mainGroup.addFile(at: root + name, sourceRoot: root)
            
            for target in projObject.targets {
                if target.productType == PBXProductType.unitTestBundle {
                    continue
                }
                let sources = (try? target.sourcesBuildPhase())!!
                _ = try sources.add(file: file)
            }
            
            
        }
        
        try! addFile(name: "SeguesSupport.swift")
        try! addFile(name: "Segues.swift")
        try! proj.write(path: Path(xcodeproj.path))
    }
}

class CustomRegex: NSRegularExpression {
    let template = ""
    let methodNameProvider: (String) -> String?
    
    init(methodNameProvider: @escaping (String) -> String?) {
        let pattern = "performSegue\\(withIdentifier: \\\"(.*)\\\", sender: (.*)\\)"
        self.methodNameProvider = methodNameProvider
        try! super.init(pattern: pattern, options: [])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func replacementString(for result: NSTextCheckingResult, in string: String, offset: Int, template templ: String) -> String {
        func getRange(_ i: Int) -> String {
            let range = result.range(at: i)
            let start = string.index(string.startIndex, offsetBy: range.lowerBound)
            let end = string.index(string.startIndex, offsetBy: range.upperBound)
            return String(string[start..<end])
        }
        
        let identifier = getRange(1)
        let sender = getRange(2)
        if let methodName = methodNameProvider(identifier) {
            return methodName + "(" + sender + ")"
        } else {
            return "<UNKNOWN SEGUE>"
        }
    }
    
    func process(code: String) -> String {
        return stringByReplacingMatches(in: code, options: [], range: NSRange.init(location: 0, length: code.count), withTemplate: template)
    }
}

class SegueNodeWorker {
    let segue: SegueNode
    let model: BundleModel
    
    init(_ segue: SegueNode, model: BundleModel) {
        self.segue = segue
        self.model = model
    }
    
    var comparisonKey: String {
        return segue.identifier ?? UUID().uuidString
    }
    
    var methodName: String = ""
    var destinationResolved: ViewControllerSceneContent?
    var vcClass = ""
    
    func resolve() {
        func getMethodName(from segueIdentifier: String) -> String {
            var name = segueIdentifier.capitalizedCharacter(at: 0)
            name = name.replacingOccurrences(of: " ", with: "_")
            
            let prefix = name.starts(with: "To") ? "navigate" : "navigateTo"
            name = prefix + name
            
            name = name.replacingOccurrences(of: "Segue", with: "")
            return name
        }
        
        vcClass = segue.parent?.customClass ?? segue.parent?.viewControllerClass ?? fallback()
        destinationResolved = try? model.locateDestination(segue: segue)
        methodName = getMethodName(from: segue.identifier ?? getAlternativeName())
    }
    
    func getAlternativeName() -> String {
        let d = destinationResolved
        if let alternativeName = d?.storyboardIdentifier ?? d?.viewControllerClass ?? segue.identifier {
            return alternativeName
        }
        
        if segue.kind == .unwind {
            let unwindAction = segue.element.getAttribute("unwindAction")!
            return unwindAction.replacingOccurrences(of: ":", with: "")
        }
        
        fatalError()
    }
    
    func convertNavigationSegue(writer: SourceWriter) {
        let segueIdentifier: String
        if let id = segue.identifier {
            segueIdentifier = "\"" + id + "\""
        } else {
            segueIdentifier = "\"\""
        }
        
        let connections = segue.element.parent as! XMLElement
        let parent = connections.parent as? XMLElement
        let name = parent!.name!
        
        segue.element.removeFromParent()
        
        switch name {
        case "barButtonItem", "button":
            let newElement = XMLElement(kind: .element)
            newElement.name = "action"
            newElement.setAttribute(name: "destination", value: segue.parent!.id)
            newElement.setAttribute(name: "id", value: segue.element.getAttribute("id")!)
            newElement.setAttribute(name: "selector", value: methodName + ":")
            newElement.setAttribute(name: "eventType", value: "touchUpInside")
            connections.addChild(newElement)
            break
        case "tableViewCell", "collectionViewCell":
            //<userDefinedRuntimeAttribute type="string" keyPath="zzzzz" value=""/>
            let newElement = XMLElement(kind: .element)
            newElement.name = "userDefinedRuntimeAttribute"
            newElement.setAttribute(name: "type", value: "string")
            newElement.setAttribute(name: "keyPath", value: "segueSelector")
            newElement.setAttribute(name: "value", value: methodName + ":")
            
            let group = XMLElement(kind: .element)
            group.name = "userDefinedRuntimeAttributes"
            group.addChild(newElement)
            parent?.addChild(group)
            break
        case "viewController", "pageViewController", "navigationController", "tableViewController":
            // do regex replace later
            break
        default:
            fatalError("Unknown parent: \(name)")
        }
        
        writer.append("@IBAction func \(methodName)(_ sender: Any?) {")
        writer.begin()
        
        writer.appendComments(segue.element.xmlString(options: .nodePrettyPrint))
        
        if let d = self.destinationResolved {
            let storyboardIdentifier: String
            if let identifier = d.storyboardIdentifier {
                storyboardIdentifier = "\"\(identifier)\""
            } else {
                storyboardIdentifier = "nil"
            }
            
            writer.append("let vc = \(d.viewControllerClass).instantiate(identifier: \(storyboardIdentifier), storyboardName: \"\(d.storyboardName)\")")
            
            if segue.kind == .presentation {
                func setStyle(name: String) {
                    if let value = segue.element.getAttribute(name) {
                        writer.append("vc.\(name) = .\(value)")
                    }
                }
                
                setStyle(name: "modalPresentationStyle")
                setStyle(name: "modalTransitionStyle")
            }
            
            if segue.kind == .popoverPresentation {
                writer.append("vc.modalPresentationStyle = .popover")
                writer.append("vc.popoverPresentationController?.sourceView = sender as? UIView")
            }
            
            if segue.kind == .custom {
                let name = segue.element.getAttribute("customClass") ?? "UIStoryboardSegue"
                writer.append("let custom = tempPrepareSegue(identifier: \(segueIdentifier), destination: vc, sender: sender, type:\(name).self)")
            } else {
                writer.append("_ = tempPrepareSegue(identifier: \(segueIdentifier), destination: vc, sender: sender)")
            }

            writer.append("_ = tempPrepareSegue(identifier: \(segueIdentifier), destination: vc, sender: sender)")
        }
        
        switch segue.kind {
        case .show:
            writer.append("show(vc, sender: self)")
            
        case .presentation:
            writer.append("present(vc, animated: true)")
            
        case .popoverPresentation:
            writer.append("present(vc, animated: true)")
            
        case .custom:
            writer.append("custom?.perform()")
            
        case .unwind:
            let selector = segue.element.getAttribute("unwindAction") ?? fallback("<UNKNOWN_SELECTOR>")
            writer.append("unwindProgrammatically(to: Selector(\"\(selector)\"), sender: self)")
            
        case .showDetail:
            writer.append("showDetailViewController(vc, sender: self)")
            
        case .relationship, .embed:
            fatalError()
        }
        
        writer.end()
        writer.append("}\n")
    }
}

class SegueConverter {
    let model: BundleModel
    let writer: SourceWriter
    
    var workers: [SegueNodeWorker] = []
    
    init(projectURL: URL) {
        model = try! BundleModel(projectURL: projectURL)
        writer = SourceWriter(path: "Segues.swift")
    }
    
    func SegueRazers() {
        copySupportFile()
        writer.append("import UIKit")
        writer.append("")
        
        for scene in model.allScenes() {
            guard scene.content.storyboardIdentifier == nil else {
                continue
            }
            
            if let content = scene.content as? ViewControllerSceneContent {
                setStoryboardIdentifier(scene: content)
            } else {
                setStoryboardIdentifier(scene: scene.content as! LinkSceneContent)
            }
        }
        
        workers = model.allSegues
            .filter { $0.kind.isNavigating }
            .map { SegueNodeWorker($0, model: model) }
        
        removeDuplicates()
        resolveDestinations()
        insertExtensions()
        
        for storyboard in model.storyboards {
            let segues = try! storyboard.document.objects(forXQuery: ".//inferredMetricsTieBreakers/segue")
            for element in segues {
                (element as! XMLElement).removeFromParent()
            }
        }
        
        removePerformSegue()
        removeEmptyLinks()
        
        writer.save()
        try! model.save()
    }
    
    func removeDuplicates() {
        var dict: [String: SegueNodeWorker] = [:]
        
        for segue in workers {
            dict[segue.comparisonKey] = segue
        }
        
        workers = Array(dict.values)
    }
    
    func resolveDestinations() {
        for s in workers {
            s.resolve()
        }
    }
    
    func insertExtensions() {
        let grouped = Dictionary(grouping: workers, by: { $0.vcClass })
        
        for (vcName, group) in grouped {
            writer.beginExtension(name: vcName)
            
            for segue in group {
                segue.convertNavigationSegue(writer: writer)
            }
            
            writer.endExtension()
        }
    }
    
    func setStoryboardIdentifier(scene: LinkSceneContent) {
        scene.storyboardIdentifier = writer.makeUnique("link")
    }
    
    func setStoryboardIdentifier(scene: ViewControllerSceneContent) {
        if scene.kind == .navigationController {
            if let segue = scene.segues.first {
                assert(segue.kind == .relationship)
                let childScene = model.locate(id: segue.destination)
                scene.storyboardIdentifier = "\(scene.viewControllerClass)\(childScene.viewControllerClass)"
            } else {
                scene.storyboardIdentifier = scene.viewControllerClass
            }
            

        } else {
            scene.storyboardIdentifier = writer.makeUnique(scene.viewControllerClass)
        }
    }
    
    func removePerformSegue() {
        let url = URL(fileURLWithPath: ".")
        let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil)!

        var currentFileName = ""
        let regex = CustomRegex { identifier in
            
            var matchingWorkers = self.workers.filter { $0.segue.identifier == identifier }
            if matchingWorkers.count > 1 {
                matchingWorkers.removeAll {
                    $0.vcClass != currentFileName
                }
            }
            
            if matchingWorkers.isEmpty {
                logWarning("Unknown segue \(identifier) in \(currentFileName)")
                return nil
            }
            
            assert(matchingWorkers.count <= 1)
            return matchingWorkers[0].methodName
        }
        
        for file in enumerator {
            currentFileName = url.deletingPathExtension().lastPathComponent
            let url = file as! URL
            guard url.lastPathComponent != "Pods" else {
                enumerator.skipDescendants()
                continue
            }
            guard url.pathExtension == "swift" else { continue }
            
            let code = try! String(contentsOf: url)
            let newCode = regex.process(code: code)
            try! newCode.write(to: url, atomically: false, encoding: .utf8)
        }
    }
    
    func copySupportFile() {
        let templateURL = Bundle(for: type(of: self)).url(forResource: "SeguesSupport", withExtension: "swift")!
        let destination = URL(fileURLWithPath: "SeguesSupport.swift")
        try? FileManager.default.removeItem(at: destination)
        try! FileManager.default.copyItem(at: templateURL, to: destination)
    }
    
    func removeEmptyLinks() {
        for scene in model.allScenes() {
            if scene.content is LinkSceneContent {
                scene.element.removeFromParent()
            }
        }
    }
}

protocol DefaultValueProviding {
    init()
}

func fallback<T>(_ value: T) -> T {
    assertionFailure()
    return value
}

extension String: DefaultValueProviding {}
extension Int: DefaultValueProviding {}

func fallback<T: DefaultValueProviding>() -> T {
    assertionFailure()
    return T.init()
}
