import UIKit

extension UITableViewController {
  @IBAction func navigateToUIViewController1(_ sender: Any?) {
    //<segue destination="zBe-u6-SoS" kind="show" id="3Tx-fJ-Qn5"/>
    let vc = UIViewController.instantiate(identifier: "UIViewController1", storyboardName: "Main")
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    show(vc, sender: self)
  }

}

extension UIViewController {
  @IBAction func navigateToObjCViewController(_ sender: Any?) {
    //<segue destination="9OP-vr-cWr" kind="show" id="UlM-f1-Ft6"/>
    let vc = ObjCViewController.instantiate(identifier: "ObjCViewController", storyboardName: "Main")
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    show(vc, sender: self)
  }

}

extension ObjCViewController {
  @IBAction func navigateToUIViewController3(_ sender: Any?) {
    //<segue destination="xmy-Mg-sje" kind="show" id="n3g-w6-YtJ"/>
    let vc = UIViewController.instantiate(identifier: "UIViewController3", storyboardName: "Main")
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    show(vc, sender: self)
  }

}

