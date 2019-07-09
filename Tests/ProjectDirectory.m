//
//  ProjectDirectory.m
//  Tests
//
//  Created by szotp on 07/07/2019.
//  Copyright © 2019 szotp. All rights reserved.
//

#import "ProjectDirectory.h"


@implementation ProjectDirectory

+ (NSURL *)get {
    return [NSURL fileURLWithPath:PROJECT_DIR];
}

@end
