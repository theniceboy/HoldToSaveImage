//
//  ViewController.swift
//  HoldToSaveImage
//
//  Created by David Chen on 9/12/15.
//  Copyright © 2015 CW Soft. All rights reserved.
//

import UIKit


class ViewController: UIViewController, UIWebViewDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var myWebView: UIWebView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Vars & Lets
    
    let kTouchJavaScriptString: String = "document.ontouchstart=function(event){x=event.targetTouches[0].clientX;y=event.targetTouches[0].clientY;document.location=\"myweb:touch:start:\"+x+\":\"+y;};document.ontouchmove=function(event){x=event.targetTouches[0].clientX;y=event.targetTouches[0].clientY;document.location=\"myweb:touch:move:\"+x+\":\"+y;};document.ontouchcancel=function(event){document.location=\"myweb:touch:cancel\";};document.ontouchend=function(event){document.location=\"myweb:touch:end\";};"
    var _gesState: Int = 0, _imgURL: String = "", _timer: NSTimer = NSTimer()
    /*
    _gesState {
        none : 0,
        start : 1,
        move : 2,
        end = 4,
    }
    */
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest _request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        
        if (_request.URL! == "about:blank") {
            return false
        }
        
        let requestString: String = (_request.URL?.absoluteString)!
        var components: [String] = requestString.componentsSeparatedByString(":")
        if (components.count > 1 && components[0] == "myweb") {
            if (components[1] == "touch") {
                if (components[2] == "start") {
                    _gesState = 1
                    let ptX: Float = Float(components[3])!
                    let ptY: Float = Float(components[4])!
                    let js: String = "document.elementFromPoint(\(ptX), \(ptY)).tagName"
                    let tagName: String = myWebView.stringByEvaluatingJavaScriptFromString(js)!
                    _imgURL = ""
                    if (tagName == "IMG") {
                        _imgURL = myWebView.stringByEvaluatingJavaScriptFromString("document.elementFromPoint(\(ptX), \(ptY)).src")!
                        _timer = NSTimer.scheduledTimerWithTimeInterval(0.3, target: self, selector: "handleLongTouch", userInfo: nil, repeats: false)
                    }
                } else {
                    if (components[2] == "move") {
                        self._gesState = 2
                    } else {
                        if (components[2] == "end") {
                            _timer.invalidate()
                            self._timer = NSTimer()
                            self._gesState = 4
                        }
                    }
                }
            }
            return false
        }
        return true
    }
    
    func handleLongTouch() {
        let hokusai = Hokusai()
        hokusai.addButton("Save") {
            Drop.down("Saving...", state: DropState.Info)
            let queue = TaskQueue()
            queue.tasks +=! {
                self.saveImage()
            }
            queue.run()
        }
        hokusai.show()
    }
    
    func saveImage () {
        if let url = NSURL(string: self._imgURL) {
            if let data = NSData(contentsOfURL: url) {
                if (UIImage(data: data) != nil) {
                    let image = UIImage(data: data)
                    UIImageWriteToSavedPhotosAlbum(image!, self, "image:didFinishSavingWithError:contextInfo:", nil)
                    return
                }
            }
        }
        Drop.down("Failed", state: DropState.Error)
    }
    
    func image(image: UIImage, didFinishSavingWithError: NSError?, contextInfo: AnyObject) {
        if didFinishSavingWithError != nil {
            Drop.down("Failed", state: DropState.Error)
            return
        }
        Drop.down("Success", state: DropState.Success)
    }
    
    // MARK: - Functions
    func loadWebPage () {
        activityIndicator.startAnimating()
        let result = Just.get("http://www.apple.com")
        if (result.ok) {
            let queue = TaskQueue()
            queue.tasks +=~ {
                self.myWebView.loadHTMLString(result.text!, baseURL: nil)
            }
                queue.run()
        } else {
            Drop.down("Error", state: DropState.Error)
        }
    }
    
    // MARK: - Override functions
    override func viewDidLoad() {
        myWebView.delegate = self
        self.tabBarController!.tabBar.hidden = true
        super.viewDidLoad()
        let queue = TaskQueue()
        queue.tasks +=! {
            self.loadWebPage()
        }
        queue.run()
    }
    
    // MARK: - UIWebView delegate
    func webViewDidFinishLoad(webView: UIWebView) {
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
        myWebView.stringByEvaluatingJavaScriptFromString(kTouchJavaScriptString)
    }
}
