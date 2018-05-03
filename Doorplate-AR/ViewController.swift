import UIKit
import Alamofire
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet weak var sceneView: ARSCNView!
    var zuehlkeAnchor: ARImageAnchor?;
    
    //TODO add Azure Cognitive Services API Key here
    let apiKey = ""
    
    var configuration: ARWorldTrackingConfiguration {
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: nil) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        let config = ARWorldTrackingConfiguration()
        config.detectionImages = referenceImages
        config.planeDetection = [.horizontal, .vertical]
        return config
    }
    
    // MARK: Lifecycle & Actions
        
    override func viewDidLoad() {
        super.viewDidLoad()
                
        self.sceneView.delegate = self
        //self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    @IBAction func resetButtonPressed(_ sender: Any) {
        resetScene()
    }
    
    // MARK: ARKit
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        /*if let planeAnchor = anchor as? ARPlaneAnchor {
            let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
            let planeNode = SCNNode(geometry: plane)
            planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
            planeNode.eulerAngles.x = -.pi / 2
            planeNode.opacity = 0.1
            node.addChildNode(planeNode)
        }*/
        if let imageAnchor = anchor as? ARImageAnchor {
            sendOCRRequest()
            self.zuehlkeAnchor = imageAnchor
            
            let height = imageAnchor.referenceImage.physicalSize.height
            let box = SCNBox(width: height, height: 0, length: height, chamferRadius: 0)
            let boxNode = SCNNode(geometry: box)
        
            let logoMaterial = SCNMaterial()
            logoMaterial.diffuse.contents = UIImage(named: "zuehlke_texture")
            logoMaterial.specular.contents = UIColor.white
            logoMaterial.locksAmbientWithDiffuse = true;
            let purpleMaterial = SCNMaterial()
            purpleMaterial.diffuse.contents = UIColor.purple
            purpleMaterial.specular.contents = UIColor.white
            purpleMaterial.locksAmbientWithDiffuse = true
            
            boxNode.geometry?.materials = [purpleMaterial, purpleMaterial, purpleMaterial, purpleMaterial, logoMaterial, purpleMaterial]

            boxNode.position = SCNVector3(0, 0, 0)
            node.addChildNode(boxNode)
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1
            box.height = height
            boxNode.pivot = SCNMatrix4MakeTranslation(0, Float(-(box.height/2)), 0)
            SCNTransaction.commit()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
    }
    
    func add3dtext(text: String){
        guard let anchor = zuehlkeAnchor else { return }
        
        let label = SCNText(string: text, extrusionDepth: 1)
        label.firstMaterial!.diffuse.contents = UIColor.purple
        label.firstMaterial!.specular.contents = UIColor.white
        label.chamferRadius = 0.1
        label.flatness = 0.1
        
        let width = (label.boundingBox.max.x - label.boundingBox.min.x) * 0.005
        
        let labelNode = SCNNode(geometry: label)
        labelNode.scale = SCNVector3(0.005, 0.005, 0.005)
        labelNode.position = SCNVector3(-width/2, 0, 0.12)
        labelNode.rotation = SCNVector4(1, 0, 0, -Double.pi/2)
        let node = sceneView.node(for: anchor)
        node?.addChildNode(labelNode)
    }
    
    func resetScene() {
        self.sceneView.session.pause()
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        self.sceneView.session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }
    
    // MARK: Cognitive Services
    
    func sendOCRRequest(){
        let buffer = self.sceneView.session.currentFrame?.capturedImage
        
        if let pixelBuffer = buffer {
            let ciImage = CIImage(cvImageBuffer: pixelBuffer)
            let context = CIContext(options: nil)
            let videoImage = context.createCGImage(ciImage,
                                                   from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer)))
            if let cgImage = videoImage{
                let uiImage = UIImage(cgImage: cgImage)
                let rotatedImage = uiImage.rotate(radians: .pi/2)
                
                detectTextWithCognitiveServices(image: rotatedImage!){
                    (result: Array<String>) in
                    print("got back: \(result)")
                    
                    let recognizedRoom = RoomInformation.validRooms.map{$0.lowercased()}
                        .filter(result.map{$0.lowercased()}.contains)
                        .first;
                    
                    if let room = recognizedRoom {
                        print("room recognized: \(room)")
                        self.add3dtext(text: RoomInformation.getTopicTeamsByRoom(roomName: room))
                    }
                }
            }
        }
    }
    
    func detectTextWithCognitiveServices(image: UIImage, completion: @escaping (_ result: Array<String>) -> Void) {
        var recognizedTexts = [String]()
        let parameters = [
            "Content-Type": "application/octet-stream"
        ]
        
        Alamofire.upload(multipartFormData: { multipartFormData in
            if let imageData = UIImageJPEGRepresentation(image, 1) {
                multipartFormData.append(imageData, withName: "file", fileName: "file.png", mimeType: "image/png")
            }
            
            for (key, value) in parameters {
                multipartFormData.append((value.data(using: .utf8))!, withName: key)
            }}, to: "https://westcentralus.api.cognitive.microsoft.com/vision/v1.0/ocr?language=de&detectOrientation=false", method: .post, headers: ["Ocp-Apim-Subscription-Key": apiKey],
                encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .success(let upload, _, _):
                        upload.response { [weak self] response in
                            guard self != nil else {
                                return
                            }
                            
                            let welcome = try? JSONDecoder().decode(Welcome.self, from: response.data!)
                            
                            for region in (welcome?.regions)!{
                                for line in region.lines{
                                    for word in line.words{
                                        recognizedTexts.append(word.text)
                                    }
                                }
                            }
                            completion(recognizedTexts)
                        }
                    case .failure(let encodingError):
                        print("error:\(encodingError)")
                    }
        })
    }
}
