import SwiftUI
import AVFoundation

struct CameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {}

    final class PreviewUIView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
}

struct SkeletonOverlayView: View {
    let points: [CGPoint]
    let isMoving: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<points.count, id: \.self) { index in
                    let pt = points[index]
                    // Vision coordinates have origin at bottom-left
                    let x = pt.x * geo.size.width
                    let y = (1.0 - pt.y) * geo.size.height

                    Circle()
                        .fill(isMoving ? Color.green : Color.orange)
                        .frame(width: 14, height: 14)
                        .shadow(color: isMoving ? .green : .orange, radius: 6)
                        .position(x: x, y: y)
                }
            }
        }
        .allowsHitTesting(false)
    }
}
