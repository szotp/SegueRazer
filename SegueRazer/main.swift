//
//  main.swift
//  SegueRazer
//
//  Created by szotp on 09/05/2018.
//  Copyright © 2018 szotp. All rights reserved.
//

import Foundation
import SegueRazerKit

#if DEBUG
print("The easiest way to run this tool is to add required parameters in the Xcode scheme\n")
#endif

CommandHandler(SegueRazer()).parseAndRun()
