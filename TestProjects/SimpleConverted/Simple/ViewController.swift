//
//  ViewController.swift
//  Simple
//
//  Created by szotp on 20/07/2018.
//  Copyright © 2018 szotp. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func onProgrammaticPressed(_ sender: Any) {
        navigateToProgrammatic(self)
    }
    
}


extension ViewController {
  @IBAction func navigateToShow(_ sender: Any?) {
    //<segue destination="cJ7-Hq-on6" kind="show" identifier="Show" id="HWN-Zc-HYn"/>
    let vc = UIViewController.instantiate(identifier: "UIViewController0", storyboardName: "Main")
    _ = tempPrepareSegue(identifier: "Show", destination: vc, sender: sender)
    _ = tempPrepareSegue(identifier: "Show", destination: vc, sender: sender)
    show(vc, sender: self)
  }

  @IBAction func navigateToUIViewController0(_ sender: Any?) {
    //<segue destination="cJ7-Hq-on6" kind="custom" customClass="CustomSegue" customModule="TestProject" customModuleProvider="target" id="e34-bO-5Vj"/>
    let vc = UIViewController.instantiate(identifier: "UIViewController0", storyboardName: "Main")
    let custom = tempPrepareSegue(identifier: "", destination: vc, sender: sender, type:CustomSegue.self)
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    custom?.perform()
  }

  @IBAction func navigateToUIViewController1(_ sender: Any?) {
    //<segue destination="zBe-u6-SoS" kind="popoverPresentation" popoverAnchorView="AFm-lJ-YGd" id="Cmz-mB-bff">
    //<popoverArrowDirection key="popoverArrowDirection" up="YES" down="YES" left="YES" right="YES"/>
    //</segue>
    let vc = UIViewController.instantiate(identifier: "UIViewController1", storyboardName: "Main")
    vc.modalPresentationStyle = .popover
    vc.popoverPresentationController?.sourceView = sender as? UIView
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    present(vc, animated: true)
  }

  @IBAction func navigateToProgrammatic(_ sender: Any?) {
    //<segue destination="cJ7-Hq-on6" kind="show" identifier="Programmatic" id="QvM-LT-jaN"/>
    let vc = UIViewController.instantiate(identifier: "UIViewController0", storyboardName: "Main")
    _ = tempPrepareSegue(identifier: "Programmatic", destination: vc, sender: sender)
    _ = tempPrepareSegue(identifier: "Programmatic", destination: vc, sender: sender)
    show(vc, sender: self)
  }

  @IBAction func navigateToCollectionViewController(_ sender: Any?) {
    //<segue destination="2ax-aG-h51" kind="show" id="dmd-CU-TN7"/>
    let vc = CollectionViewController.instantiate(identifier: "CollectionViewController", storyboardName: "Main")
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    show(vc, sender: self)
  }

  @IBAction func navigateToPresentModally(_ sender: Any?) {
    //<segue destination="fMw-I1-9k8" kind="presentation" identifier="PresentModally" animates="NO" modalPresentationStyle="fullScreen" modalTransitionStyle="partialCurl" id="5cp-wr-A8G"/>
    let vc = CustomNavigationController.instantiate(identifier: "CustomNavigationControllerUIViewController", storyboardName: "Main")
    vc.modalPresentationStyle = .fullScreen
    vc.modalTransitionStyle = .partialCurl
    _ = tempPrepareSegue(identifier: "PresentModally", destination: vc, sender: sender)
    _ = tempPrepareSegue(identifier: "PresentModally", destination: vc, sender: sender)
    present(vc, animated: true)
  }

  @IBAction func navigateToUITableViewController(_ sender: Any?) {
    //<segue destination="nDB-8t-45s" kind="show" id="Ptc-gy-aNt"/>
    let vc = UITableViewController.instantiate(identifier: "UITableViewController", storyboardName: "Main")
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    show(vc, sender: self)
  }

  @IBAction func navigateToShowDetail(_ sender: Any?) {
    //<segue destination="cJ7-Hq-on6" kind="showDetail" identifier="ShowDetail" id="nMR-b7-PlI"/>
    let vc = UIViewController.instantiate(identifier: "UIViewController0", storyboardName: "Main")
    _ = tempPrepareSegue(identifier: "ShowDetail", destination: vc, sender: sender)
    _ = tempPrepareSegue(identifier: "ShowDetail", destination: vc, sender: sender)
    showDetailViewController(vc, sender: self)
  }

}

