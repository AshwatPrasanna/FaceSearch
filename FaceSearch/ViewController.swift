//
//  ViewController.swift
//  FaceSearch
//
//  Created by Ashwat on 15/11/2020.
//

import UIKit
import WebKit
import ARKit

class ViewController: UIViewController, UIWebViewDelegate, WKNavigationDelegate, ARSessionDelegate, UIScrollViewDelegate {
    var wbView: WKWebView!
    
    var session: ARSession!
    var isBusy = false
    
    override func loadView() {
        wbView = WKWebView()
        wbView.navigationDelegate = self
        view = wbView
    }
    
    func performTouchInView(view: UIView) {
        let touch = UITouch()
        let eventDown = UIEvent()

        view.touchesBegan([touch], with: eventDown)

        let eventUp = UIEvent()

        view.touchesEnded([touch], with: eventUp)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        wbView.navigationDelegate = self
        
        let url = URL(string: "https://www.google.com")!
        wbView.load(URLRequest(url: url))
        wbView.allowsBackForwardNavigationGestures = true
        
        session = ARSession()
        session.delegate = self
        
        wbView.scrollView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        guard ARFaceTrackingConfiguration.isSupported else {
            let alert = UIAlertController(title: "Not Supported on this device", message: "A TrueDepth camera is required for this particular feature", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) in
                fatalError("needs TrueDepth camera")
            }))
            
            self.present(alert, animated: true)
            
            return
        }
        
        let config = ARFaceTrackingConfiguration()
        session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }
    
    func scrollDown() {
        
        isBusy = true
        
        if wbView.scrollView.contentSize.height - wbView.scrollView.contentOffset.y - (wbView.frame.height) >= 450{
            wbView.scrollView.setContentOffset(CGPoint(x: wbView.scrollView.contentOffset.x, y: wbView.scrollView.contentOffset.y + 300), animated: true)
        }
        else {
            wbView.scrollView.setContentOffset(CGPoint(x: wbView.scrollView.contentOffset.x, y: wbView.scrollView.contentSize.height - (wbView.frame.height)), animated: true)
            isBusy = false
        }
    }
    
    func scrollUp() {
        
        isBusy = true
        
        if wbView.scrollView.contentOffset.y >= 450 {
            wbView.scrollView.setContentOffset(CGPoint(x: wbView.scrollView.contentOffset.x, y: wbView.scrollView.contentOffset.y - 300), animated: true)
        }
        else {
            wbView.scrollView.setContentOffset(CGPoint(x: wbView.scrollView.contentOffset.x, y: -20), animated: true) // for the iOS title bar, etc.
            isBusy = false
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        isBusy = false
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isBusy = true
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        isBusy = false
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        isBusy = false
    }
    
    // MARK: ARSessionDelegate functions
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        if let faceAnchor = anchors.first as? ARFaceAnchor {
            update(withFaceAnchor: faceAnchor)
        }
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        isBusy = false
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        isBusy = false
    }
    
    func enterText() {
        wbView.evaluateJavaScript("document.getElementsByTagName('input')[0].click()", completionHandler: nil)
    }
    
    func update(withFaceAnchor faceAnchor: ARFaceAnchor) {
        
        let blendShapes: [ARFaceAnchor.BlendShapeLocation:Any] = faceAnchor.blendShapes
        
        print(faceAnchor.isTracked)
        
        guard !isBusy else { return }
        
        guard let browInnerUp = blendShapes[.browInnerUp] as? Float else {
            return
        }
        
        if browInnerUp > 0.8 {
            scrollDown()
        }
        else if browInnerUp < 0.06 {
            scrollUp()
        }
        
        guard let eyeLeft = blendShapes[.eyeBlinkRight] as? Float else { // left and right swapped
            return
        }
        
        guard let eyeRight = blendShapes[.eyeBlinkLeft] as? Float else { // left and right swapped
            return
        }
        
        if eyeRight > 0.825 && eyeLeft < 0.6 {
            
            if wbView.canGoBack {
                wbView.goBack()
            } else {
                wbView.reload()
            }
        } else if eyeLeft > 0.825 && eyeRight < 0.6 {
            
            if wbView.canGoForward {
                wbView.goForward()
            } else {
                wbView.reload()
            }
        }
    }
}

