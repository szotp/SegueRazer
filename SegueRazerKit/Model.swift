import Foundation

class BundleModel {
    let projectURL: URL
    let storyboards: [StoryboardNode]
    
    private(set) lazy var allSegues: [SegueNode] = getAllSegues()
    private(set) lazy var seguesByIdentifier: [String: [SegueNode]] = getSeguesByIdentifier()
    
    func storyboard(named: String) -> StoryboardNode {
        return (storyboards.first { $0.name == named })!
    }
    
    init(projectURL: URL) throws {
        self.projectURL = projectURL
        let urls = BundleModel.fetchURLs(projectURL: projectURL)
        storyboards = try urls.map(StoryboardNode.init)
    }
    
    private func getSeguesByIdentifier() -> [String: [SegueNode]] {
        let filtered = allSegues.filter { $0.identifier != nil }
        return Dictionary(grouping: filtered, by: { $0.identifier! })
    }
    
    private func getAllSegues() -> [SegueNode] {
        var segues: [SegueNode] = []
        
        for storyboard in storyboards {
            for scene in storyboard.scenes {
                if let vc = scene.content as? ViewControllerSceneContent {
                    segues.append(contentsOf: vc.segues)
                }
            }
        }
        
        return segues
    }
    
    func locate(id: String) -> ViewControllerSceneContent {
        for storyboard in self.storyboards {
            if let scene = storyboard.scene(id: id) {
                return scene.content as! ViewControllerSceneContent
            }
        }
        
        fatalError()
    }
    
    func locateDestination(segue: SegueNode) throws -> ViewControllerSceneContent {
        let storyboard = segue.parent!.parent!.parent!
        let scene = try storyboard.scene(id: segue.destination).get()
        
        if let scene = scene.content as? ViewControllerSceneContent {
            return scene
        }
        else if let scene = scene.content as? LinkSceneContent {
            
            let destinationStoryboard = self.storyboard(named: scene.referencedStoryboardName)
            let destinationScene = destinationStoryboard.scene(storyboardIdentifier: scene.referencedStoryboardIdentifier)!
            let destinationVC = destinationScene.content as! ViewControllerSceneContent
            return destinationVC
        } else {
            fatalError()
        }
    }
    
    static func fetchURLs(projectURL: URL) -> [URL] {
        let enumerator = FileManager.default.enumerator(at: projectURL, includingPropertiesForKeys: nil)!
        var result: [URL] = []
        
        for file in enumerator {
            let url = file as! URL
            if url.path == "Pods" {
                enumerator.skipDescendants()
                continue
            }
            
            if url.pathExtension == "storyboard" {
                result.append(url)
            }
            
        }
        
        return result
    }
    
    func allScenes() -> [SceneNode] {
        return storyboards.flatMap { $0.scenes }
    }
    
    func save() throws {
        for storyboard in storyboards {
            try storyboard.save()
        }
    }
}

class NodeBase: CustomStringConvertible {
    var description: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(DebuggingEncodable(value: self))
        let string = String(data: data, encoding: .utf8)!
        return string
    }
}

class ElementWrapper<Parent>: NodeBase where Parent: AnyObject {
    weak var parent: Parent?
    let element: XMLElement
    
    required init(_ element: XMLElement) throws {
        self.element = element
    }
}

class StoryboardNode: NodeBase {
    let url: URL
    let name: String
    
    var debugDescription: String {
        return name
    }
    
    var initialScene: SceneNode {
        let initial = document.rootElement()?.attribute(forName: "initialViewController")?.stringValue
        return scene(id: initial!)!
    }
    
    func scene(storyboardIdentifier: String?) -> SceneNode? {
        if storyboardIdentifier == nil {
            return initialScene
        }
        
        return scenes.first(where: { (scene) -> Bool in
            return scene.content.storyboardIdentifier == storyboardIdentifier
        })
    }
    
    func scene(id: String) -> SceneNode? {
        return scenes.first(where: { (scene) -> Bool in
            if scene.content.id == id {
                return true
            }
            
            
            return false
        })
    }
    
    let document: XMLDocument
    let scenes: [SceneNode]
    
    init(url: URL) throws {
        self.url = url
        self.name = url.lastPathComponent.replacingOccurrences(of: ".storyboard", with: "")
        document = try XMLDocument(contentsOf: url, options: [XMLNode.Options.nodePreserveAll])
        
        let scenes = try document.objects(forXQuery: "document/scenes/scene")
        self.scenes = try scenes.map {
            return try SceneNode($0 as! XMLElement)
        }
        
        super.init()
        
        for scene in self.scenes {
            scene.parent = self
        }
    }
    
    func save() throws {
        var data = document.xmlString
        data.append("\n")
        try data.write(to: url, atomically: false, encoding: .utf8)
    }
}

class SceneNode: ElementWrapper<StoryboardNode> {
    let content: SceneContent

    required init(_ element: XMLElement) throws {
        let objects = try element.objects(forXQuery: "objects/*") as! [XMLElement]
        let object = objects.first { $0.name != "placeholder" }!
        
        if object.name == "viewControllerPlaceholder" {
            content = try LinkSceneContent(object)
        } else {
            content = try ViewControllerSceneContent(object)
        }
        
        try super.init(element)
        content.parent = self
    }
}

class SceneContent: ElementWrapper<SceneNode> {
    let id: String
    var storyboardIdentifier: String? {
        get {
            return element.getAttribute("storyboardIdentifier")
        }
        set {
            element.setAttribute(name: "storyboardIdentifier", value: newValue!)
        }
    }
    
    required init(_ element: XMLElement) throws {
        id = element.attribute(forName: "id")!.stringValue!
        try super.init(element)
    }
}

class LinkSceneContent: SceneContent {
    let referencedStoryboardName: String
    let referencedStoryboardIdentifier: String?
    
    required init(_ element: XMLElement) throws {
        referencedStoryboardName = element.attribute(forName: "storyboardName")!.stringValue!
        referencedStoryboardIdentifier = element.attribute(forName: "referencedIdentifier")?.stringValue
        
        try super.init(element)
    }
}

enum ViewControllerKind: String {
    case viewController
    case navigationController
    case tableViewController
    case pageViewController
    case splitViewController
    case collectionViewController
}

class ViewControllerSceneContent: SceneContent {
    let segues: [SegueNode]
    let kind: ViewControllerKind
    
    let customClass: String?
    let viewControllerClass: String
    
    var storyboardName: String {
        return parent!.parent!.name
    }
    
    required init(_ element: XMLElement) throws {
        kind = ViewControllerKind(rawValue: element.name!)!
        customClass = element.attribute(forName: "customClass")?.stringValue
        
        func getViewControllerClass(name: String) -> String {
            return "UI" + name.capitalizedCharacter(at: 0)
        }
        
        viewControllerClass = customClass ?? getViewControllerClass(name: element.name!)
        
        segues = try! element.objects(forXQuery: ".//segue").compactMap { element in
            let segueElement = element as! XMLElement
            return try! SegueNode(segueElement)
        }
        
        try super.init(element)
        
        for segue in segues {
            segue.parent = self
        }
    }
}

class SegueNode: ElementWrapper<ViewControllerSceneContent> {
    enum Kind: String {
        case show, showDetail, presentation, popoverPresentation, custom, unwind, relationship, embed
        
        var isNavigating: Bool {
            return self != .relationship && self != .embed
        }
    }
    
    let destination: String
    let identifier: String?
    let kind: Kind
    
    required init(_ element: XMLElement) throws {
        destination = element.attribute(forName: "destination")!.stringValue!
        identifier = element.attribute(forName: "identifier")?.stringValue
        kind = Kind(rawValue: element.attribute(forName: "kind")!.stringValue!)!
        try super.init(element)
    }
}
