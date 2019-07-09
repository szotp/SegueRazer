//
//  CollectionViewController.swift
//  Simple
//
//  Created by szotp on 07/07/2019.
//  Copyright © 2019 szotp. All rights reserved.
//

import UIKit

class CollectionViewController: UICollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
    }
}

class CustomSegue: UIStoryboardSegue {
    override func perform() {
        print("Custom segue")
    }
}

extension CollectionViewController {
  static func instantiate() -> Self {
    return instantiate(identifier: "CollectionViewController", storyboardName: "Main")
  }
}


extension CollectionViewController {
  @IBAction func navigateToUIViewController1(_ sender: Any?) {
    //<segue destination="zBe-u6-SoS" kind="show" id="HCu-w1-egU"/>
    let vc = UIViewController.instantiateVC1()
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    _ = tempPrepareSegue(identifier: "", destination: vc, sender: sender)
    show(vc, sender: self)
  }

}

