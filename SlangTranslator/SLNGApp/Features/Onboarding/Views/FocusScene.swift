//
//  FocusScene.swift
//  SlangTranslator
//
//  Created by Filza Rizki Ramadhan on 06/11/25.
//
import SwiftUI
import SpriteKit

struct dataScene {
    let id: UUID
    let title: String
    let color: Color
    let textColor: Color
}

final class FocusScene: SKScene {
    private let data: [dataScene]
    private let displayScale: CGFloat
    private let backgroundColorConfig: SKColor
    private let restitution: CGFloat
    private let gravityY: CGFloat
    private let startDelaY: TimeInterval
    private let onSelectionChange: ([String]) -> Void
    private var chipNodes: [(node: SKSpriteNode, data: dataScene)] = []
    
    private var selectedNode: SKSpriteNode?
    private var touchStartPos: CGPoint = .zero
    private var nodePrevPos: CGPoint = .zero
    
    init(size: CGSize ,data: [dataScene], displayScale: CGFloat, backgroundColor: SKColor, restitution: CGFloat, gravityY: CGFloat, startDelaY: TimeInterval, onSelectionChange: @escaping ([String]) -> Void) {
        self.data = data
        self.displayScale = displayScale
        self.backgroundColorConfig = backgroundColor
        self.restitution = restitution
        self.gravityY = gravityY
        self.startDelaY = startDelaY
        self.onSelectionChange = onSelectionChange
        super.init(size: size)
        scaleMode = .resizeFill
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func didMove(to view: SKView) {
        backgroundColor = backgroundColorConfig
        let extendedFrame = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: frame.height + 1000)
        physicsBody = SKPhysicsBody(edgeLoopFrom: extendedFrame)
        physicsWorld.gravity = CGVector(dx: 0, dy: gravityY)
        let attractor = SKFieldNode.radialGravityField()
        attractor.categoryBitMask = 0x40
        attractor.strength = 0.0
        attractor.falloff = 0.0
        attractor.minimumRadius = 100
        attractor.position = CGPoint(x: frame.midX, y: frame.height * 0.2)
        addChild(attractor)
        self.spawn(y: self.frame.height + 200)
    }
    
    private func spawn(y: CGFloat) {
        chipNodes.removeAll()
        
        for dto in data {
            let delay = Double.random(in: 0.05...1.2)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                let view = self.renderedChipView(dto)
                let image = self.render(view: view)
                let texture = SKTexture(image: image)
                let node = SKSpriteNode(texture: texture)
                node.size = image.size
                
                let corner = node.size.height / 2
                let bodyRect = CGRect(
                    origin: CGPoint(x: -node.size.width/2, y: -node.size.height/2),
                    size: node.size
                )
                let path = CGPath(
                    roundedRect: bodyRect,
                    cornerWidth: corner,
                    cornerHeight: corner,
                    transform: nil
                )
                
                node.physicsBody = SKPhysicsBody(polygonFrom: path)
                node.physicsBody?.restitution = self.restitution
                node.physicsBody?.usesPreciseCollisionDetection = true
                node.physicsBody?.allowsRotation = true
                node.name = dto.id.uuidString
                
                let w = node.frame.width
                let x = CGFloat.random(in: (w/2 + 16)...(self.size.width - w/2 - 16))
                let randomY = y + CGFloat.random(in: 0...100)
                
                node.position = CGPoint(x: x, y: randomY)
                node.alpha = 0
                
                let fadeInDuration = Double.random(in: 0.1...0.2)
                node.run(.fadeIn(withDuration: fadeInDuration))
                
                self.addChild(node)
                self.chipNodes.append((node, dto))
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        let touchedNodes = nodes(at: location)
        for node in touchedNodes {
            if let spriteNode = node as? SKSpriteNode,
               chipNodes.contains(where: { $0.node == spriteNode }) {
                selectedNode = spriteNode
                touchStartPos = location
                nodePrevPos = spriteNode.position
                
                spriteNode.physicsBody?.isDynamic = false
                spriteNode.removeAllActions()
                spriteNode.zPosition = 100
                
                let scaleUp = SKAction.scale(to: 1.1, duration: 0.1)
                spriteNode.run(scaleUp)
                break
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let node = selectedNode else { return }
        
        let location = touch.location(in: self)
        node.position = location
        
        let dx = location.x - touchStartPos.x
        let angle = dx / 200
        node.zRotation = angle
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
              let node = selectedNode else { return }
        
        let location = touch.location(in: self)
        let dx = location.x - touchStartPos.x
        let dy = location.y - touchStartPos.y
        
        let velocity = CGVector(
            dx: dx * 20,
            dy: dy * 20
        )
        
        let throwThreshold: CGFloat = 100
        let shouldThrow = abs(dx) > throwThreshold || dy > throwThreshold
        
        if shouldThrow {
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([fadeOut, remove])
            
            node.physicsBody?.isDynamic = true
            node.physicsBody?.velocity = velocity
            node.physicsBody?.angularVelocity = CGFloat.random(in: -5...5)
            
            node.run(sequence) {
                if let index = self.chipNodes.firstIndex(where: { $0.node == node }) {
                    self.chipNodes.remove(at: index)
                }
                
                if self.chipNodes.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.spawn(y: self.frame.height + 200)
                    }
                }
            }
        } else {
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
            let rotateBack = SKAction.rotate(toAngle: 0, duration: 0.2)
            node.run(SKAction.group([scaleDown, rotateBack]))
            
            node.physicsBody?.isDynamic = true
            node.physicsBody?.velocity = .zero
            node.physicsBody?.angularVelocity = 0
            node.zPosition = 0
        }
        
        selectedNode = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let node = selectedNode {
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.2)
            let rotateBack = SKAction.rotate(toAngle: 0, duration: 0.2)
            node.run(SKAction.group([scaleDown, rotateBack]))
            
            node.physicsBody?.isDynamic = true
            node.zPosition = 0
        }
        selectedNode = nil
    }
    
    private func renderedChipView(_ data: dataScene) -> some View {
        HStack{
            Text(data.title)
                .font(.system(size: 25))
                .foregroundColor(data.textColor)
                .frame(height: 30)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(data.color, in: .capsule)
        .overlay(Capsule().strokeBorder(AppColor.Button.primary, lineWidth: 2))
    }
    
    private func render(view: some View) -> UIImage {
        let renderer = ImageRenderer(content: view)
        renderer.scale = displayScale
        renderer.isOpaque = false
        return renderer.uiImage ?? UIImage()
    }
}
