// Created by SegueRazer tool
// TODO: remove this file after refactoring usage of tempPrepareSegue and segueSelector
#if canImport(UIKit)
import UIKit

protocol StoryboardScene { }

extension UIViewController : StoryboardScene { }

extension StoryboardScene where Self: UIViewController {
    static func instantiate(identifier: String? = nil, storyboardName: String) -> Self {
        let storyboard = UIStoryboard.init(name: storyboardName, bundle: nil)
        
        if let identifier = identifier {
            return storyboard.instantiateViewController(withIdentifier: identifier) as! Self
        } else {
            return storyboard.instantiateInitialViewController() as! Self
        }
    }
}

extension UIViewController {
    /// A hack to use existing prepareForSegue methods
    /// Refactor this into storyboards or create factory methods on your view controllers that will create the VC with desired configuration
    func tempPrepareSegue(identifier: String, destination: UIViewController, sender: Any?, type: UIStoryboardSegue.Type = UIStoryboardSegue.self) -> UIStoryboardSegue? {
        if shouldPerformSegue(withIdentifier: identifier, sender: sender) {
            let segue = type.init(identifier: identifier, source: self, destination: destination)
            prepare(for: segue, sender: sender)
            return segue
        } else {
            return nil
        }
    }
    
    func unwindProgrammatically(to selector: Selector, sender: Any?) {
        assertionFailure("Not implemented")
    }
}

private var segueSelectorHandle = 0
extension UIView {
    /// Hack to connect cells with IBActions
    /// Tool inserted segueSelector setters into storyboard
    /// During VC creation, storyboard initializer will call setter of this property and create UITapGestureRecognizer
    /// Typically should be moved into didSelect methods
    /// Or into cell classes itself
    @objc var segueSelector: String? {
        get {
            return objc_getAssociatedObject(self, &segueSelectorHandle) as? String
        }
        set {
            assert(segueSelector == nil)
            objc_setAssociatedObject(self, &segueSelectorHandle, newValue, .OBJC_ASSOCIATION_COPY)
            
            let recognizer = UITapGestureRecognizer(target: self, action: #selector(performSegueSelectorIfNeeded))
            self.addGestureRecognizer(recognizer)
        }
    }
    
    @objc func performSegueSelectorIfNeeded() {
        func getViewController() -> UIViewController? {
            var responder: UIResponder? = self
            
            while responder != nil {
                if let vc = responder as? UIViewController {
                    return vc
                }
                
                responder = responder?.next
            }
            
            return nil
        }
        
        guard let selString = self.segueSelector else {
            return
        }
        let sel = Selector(selString)
        
        guard let vc = getViewController() else {
            assertionFailure()
            return
        }
        
        if vc.responds(to: sel) {
            _ = vc.perform(sel, with: self)
        } else {
            assertionFailure()
        }
    }
}
#endif
