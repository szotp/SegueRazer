```
SegueRazer
Razes navigation segues from storyboards and replaces them with explicit instantiation.
-projectURL                    Path to directory containing xcode proj (URL)
-shouldAddFilesToXcodeProj     Should attempt to edit xcodeproj? (Bool, default: true)
```
### Explanation
Removing segues is not an easy task. After SegueRazer finishes it's job, you will have to go over the changes, cleanup the generated code, write your own coordinators, etc.

1. Commit all your changes and push them somewhere safe.
2. Run this tool on your project with -projectURL <path to root directory of your project>.
3. Wait until changes have been applied.
4. Open your project in Xcode and ensure that it compiles - it should.
4. At this point all navigation segues have been replaced by IBAction. Extensions were added to your files that explictly create the view controllers and show/present them.
5. Look for Segue.swift and SegueSupport.swift files that were generated. These act as scaffolding until you finalize the migration. 
5. Look for performSegue calls - this tool only replaces performSegues executed with string literals. Replace them with proper navigateTo calls.
5. Look for `func navigateTo` in your project. This is where SegueRazer generated code for you. 

```swift
@IBAction func navigateToShow(_ sender: Any?) {
    //<segue destination="cJ7-Hq-on6" kind="show" identifier="Show" id="HWN-Zc-HYn"/>
    let vc = UIViewController.instantiate(identifier: "UIViewController0", storyboardName: "Main")
    _ = tempPrepareSegue(identifier: "Show", destination: vc, sender: sender)
    show(vc, sender: self)
}
```

6. If you have unwind or custom segues you need to fix them manually. The code for them has been inserted, but it will not work without further changes.
7. Eventually you should be able to get rid of Segue.swift and SegueSupport.swift that were created by this tool. They only purpose

