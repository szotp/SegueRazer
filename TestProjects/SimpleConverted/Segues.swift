import UIKit

extension CustomNavigationController {
  static func instantiateWithUIViewController() -> Self {
    return instantiate(identifier: "CustomNavigationControllerUIViewController", storyboardName: "Main")
  }
}

extension ObjCViewController {
  static func instantiate() -> Self {
    return instantiate(identifier: "ObjCViewController", storyboardName: "Main")
  }
}

extension UITableViewController {
  static func instantiate() -> Self {
    return instantiate(identifier: "UITableViewController", storyboardName: "Main")
  }
}

extension UIViewController {
  static func instantiateVC1() -> Self {
    return instantiate(identifier: "UIViewController1", storyboardName: "Main")
  }
  static func instantiateVC() -> Self {
    return instantiate(identifier: "UIViewController0", storyboardName: "Main")
  }
}

extension UITableViewController {
  @IBAction func navigateToUIViewController1(_ sender: Any?) {
    //<segue destination="zBe-u6-SoS" kind="show" id="3Tx-fJ-Qn5"/>
    let vc = UIViewController.instantiateVC1()
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    show(vc, sender: self)
  }

}

extension UIViewController {
  @IBAction func navigateToObjCViewController(_ sender: Any?) {
    //<segue destination="9OP-vr-cWr" kind="show" id="UlM-f1-Ft6"/>
    let vc = ObjCViewController.instantiate()
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    show(vc, sender: self)
  }

}

extension ObjCViewController {
  @IBAction func navigateToViewController0(_ sender: Any?) {
    //<segue destination="xmy-Mg-sje" kind="show" id="n3g-w6-YtJ"/>
    let vc = ViewController.instantiate()
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    show(vc, sender: self)
  }

}

