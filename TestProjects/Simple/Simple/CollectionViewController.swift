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

class CustomSegue: UIStoryboardSegue {}
