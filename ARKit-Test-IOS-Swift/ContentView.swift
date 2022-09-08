//
//  ContentView.swift
//  ARKit-Test-IOS-Swift
//
//  Created by steffan crowley on 9/6/22.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct ContentView : View {
    @State private var isPlacementEnabled = false
    @State private var selectedModel: String?
    @State private var modelConfirmedForPlacement: String?
    
    
    private var Models: [String] = {
        let filemanager = FileManager.default
        
        guard let path = Bundle.main.resourcePath, let files = try?
                filemanager.contentsOfDirectory(atPath: path) else {
                    return []
        }
        var availableModels: [String] = []
        
        for filename in files where
        filename.hasSuffix("usdz") {
            let modelName =
            filename.replacingOccurrences(of:".usdz", with:"")
            availableModels.append(modelName)
        }
        
        return availableModels
    }()
    
    var body: some View {
        ZStack (alignment: .bottom) {
            //All the AR magic below
            ARViewContainer(modelConfirmedForPlacement: $modelConfirmedForPlacement)
            
            //below is for placement menu bar
            if isPlacementEnabled {
                PlacementButtonsView(isPlacementEnabled: $isPlacementEnabled, selectedModel: $selectedModel, modelConfirmedForPlacement: $modelConfirmedForPlacement)
            } else {
                ModelPickerView(isPlacementEnabled: $isPlacementEnabled, selectedModel: $selectedModel, Models: Models)
            }

        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    @Binding var modelConfirmedForPlacement: String?
    
    
    func makeUIView(context: Context) -> ARView {
        
        let arView = ARView(frame: .zero)
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            config.sceneReconstruction = .mesh
        }
        
        arView.session.run(config)

        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        if let modelName = modelConfirmedForPlacement {
            print("DEBUG: adding model scene - \(modelName)")
            
            let filename = modelName + ".usdz"
            
            let modelEntity = try! ModelEntity.loadModel(named: filename)
            
            let anchorEntity = AnchorEntity(plane:.any)
            
            anchorEntity.addChild(modelEntity)
            
            uiView.scene.addAnchor(anchorEntity)
            
            let entityBounds = modelEntity.visualBounds(relativeTo: modelEntity)
            
            modelEntity.collision = CollisionComponent(shapes: [ShapeResource.generateBox(size: entityBounds.extents).offsetBy(translation: entityBounds.center)])
                       
            // installing gestures for the parentEntity
            uiView.installGestures(for: modelEntity)
            
//            var collisionSubscription = uiView.scene.publisher(for: CollisionEvents.Began.self,
//                                                                   on:nil).sink(receiveValue: onCollisionBegan)
            
            DispatchQueue.main.async {
                modelConfirmedForPlacement = nil
            }
        }
    }
    
    private func onCollisionBegan(_ event:
                                  CollisionEvents.Began) {
        print("collision started")
        // Take appropriate action...
    }
    
}

struct ModelPickerView: View {
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: String?
    
    var Models: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 30) {
                ForEach(0..<4) { index in
                    Button {
                        selectedModel = Models[index]
                        isPlacementEnabled = true
                    } label: {
                        Image(Models[index])
                            .resizable()
                            .frame(height: 80)
                            .aspectRatio(1/1, contentMode: .fit)
                    }
                }
                
            }
        }
        .padding(20)
        .background(Color.black.opacity(0.5))
    }
}

struct PlacementButtonsView: View {
    @Binding var isPlacementEnabled: Bool
    @Binding var selectedModel: String?
    @Binding var modelConfirmedForPlacement: String?
    
    var body: some View {
        HStack {
            Button {
                print("Cancel")
                isPlacementEnabled = false
                selectedModel = nil
            }label: {
                Image(systemName: "xmark")
                    .frame(width:60, height: 60)
                    .font(.title)
                    .background(Color.white .opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            }
            
            Button {
                print("Confirm")
                modelConfirmedForPlacement = selectedModel
                isPlacementEnabled = false
                selectedModel = nil
            }label: {
                Image(systemName: "checkmark")
                    .frame(width:60, height: 60)
                    .font(.title)
                    .background(Color.white .opacity(0.75))
                    .cornerRadius(30)
                    .padding(20)
            }
        }
    }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
                .previewDevice("iPad Pro (11-inch) (3rd generation)")
        }
    }
}
#endif
