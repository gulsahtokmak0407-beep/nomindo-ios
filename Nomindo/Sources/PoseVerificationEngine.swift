import Foundation
import AVFoundation
import Vision
import UIKit

final class PoseVerificationEngine: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var isCameraAuthorized: Bool = false
    @Published var hasHardwareCamera: Bool = false
    @Published var cameraErrorMessage: String? = nil
    @Published var isHumanDetected: Bool = false
    @Published var isActivelyMoving: Bool = false
    @Published var detectedJointPoints: [CGPoint] = []
    @Published var progressSeconds: Double = 0.0
    @Published var statusHeadline: String = "KAMERA BAŞLATILIYOR..."

    let requiredSeconds: Double = 30.0
    let captureSession = AVCaptureSession()

    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.nomindo.cameraQueue")
    private var previousJoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    private var lastFrameTimestamp: Date = Date()
    private var movementHoldUntil: Date = Date.distantPast
    private var isConfigured = false
    var onVerificationComplete: (() -> Void)?

    override init() {
        super.init()
    }

    func startSession() {
        progressSeconds = 0.0
        previousJoints.removeAll()
        cameraErrorMessage = nil

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            DispatchQueue.main.async { self.isCameraAuthorized = true }
            configureAndRunCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.isCameraAuthorized = granted
                    if granted {
                        self.configureAndRunCamera()
                    } else {
                        self.cameraErrorMessage = "KAMERA İZNİ REDDEDİLDİ! AYARLARDAN İZİN VERMEDEN ALARM KAPATILAMAZ."
                    }
                }
            }
        default:
            DispatchQueue.main.async {
                self.isCameraAuthorized = false
                self.cameraErrorMessage = "KAMERA ENGELLENDİ! GERÇEK KAMERA OLMADAN ALARM KAPATILAMAZ."
            }
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
        }
    }

    private func configureAndRunCamera() {
        sessionQueue.async {
            if !self.isConfigured {
                self.captureSession.beginConfiguration()
                self.captureSession.sessionPreset = .high

                let discovery = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.builtInWideAngleCamera],
                    mediaType: .video,
                    position: .front
                )
                let fallbackDiscovery = AVCaptureDevice.DiscoverySession(
                    deviceTypes: [.builtInWideAngleCamera],
                    mediaType: .video,
                    position: .back
                )

                guard let cameraDevice = discovery.devices.first ?? fallbackDiscovery.devices.first else {
                    self.captureSession.commitConfiguration()
                    DispatchQueue.main.async {
                        self.hasHardwareCamera = false
                        self.cameraErrorMessage = "DONANIM KAMERASI BULUNAMADI! BU CİHAZDA ALARM DOĞRULANAMAZ."
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.hasHardwareCamera = true
                }

                do {
                    let input = try AVCaptureDeviceInput(device: cameraDevice)
                    if self.captureSession.canAddInput(input) {
                        self.captureSession.addInput(input)
                    }
                } catch {
                    self.captureSession.commitConfiguration()
                    DispatchQueue.main.async {
                        self.cameraErrorMessage = "KAMERA GİRİŞ HATASI: \(error.localizedDescription)"
                    }
                    return
                }

                self.videoOutput.setSampleBufferDelegate(self, queue: self.sessionQueue)
                self.videoOutput.alwaysDiscardsLateVideoFrames = true
                if self.captureSession.canAddOutput(self.videoOutput) {
                    self.captureSession.addOutput(self.videoOutput)
                }

                self.captureSession.commitConfiguration()
                self.isConfigured = true
            }

            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
            self.lastFrameTimestamp = Date()
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let now = Date()
        let deltaTime = min(now.timeIntervalSince(lastFrameTimestamp), 0.25)
        lastFrameTimestamp = now

        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:])

        do {
            try handler.perform([request])
            guard let observation = request.results?.first else {
                updateNoHumanState()
                return
            }

            let recognizedPoints = try observation.recognizedPoints(.all)
            let trackedJoints: [VNHumanBodyPoseObservation.JointName] = [
                .nose, .leftShoulder, .rightShoulder,
                .leftElbow, .rightElbow, .leftWrist, .rightWrist,
                .leftHip, .rightHip, .leftKnee, .rightKnee
            ]

            var validPoints: [CGPoint] = []
            var totalDisplacement: CGFloat = 0.0
            var comparedCount: CGFloat = 0.0

            for joint in trackedJoints {
                if let point = recognizedPoints[joint], point.confidence > 0.35 {
                    let loc = point.location
                    validPoints.append(loc)
                    if let prev = previousJoints[joint] {
                        let dist = hypot(loc.x - prev.x, loc.y - prev.y)
                        totalDisplacement += dist
                        comparedCount += 1.0
                    }
                    previousJoints[joint] = loc
                }
            }

            let isBodyVisible = validPoints.count >= 4
            let avgMovement = comparedCount > 0 ? (totalDisplacement / comparedCount) : 0.0

            if isBodyVisible && avgMovement > 0.014 {
                movementHoldUntil = now.addingTimeInterval(0.65)
            }

            let movingNow = isBodyVisible && (now < movementHoldUntil)

            DispatchQueue.main.async {
                self.isHumanDetected = isBodyVisible
                self.detectedJointPoints = validPoints
                self.isActivelyMoving = movingNow

                if !isBodyVisible {
                    self.statusHeadline = "VÜCUT ALGILANMADI! KADRAJA GİR!"
                    AlarmSoundEngine.shared.startAlarm()
                } else if movingNow {
                    self.statusHeadline = "HARİKA! DURMADAN DEVAM ET!"
                    self.progressSeconds = min(self.requiredSeconds, self.progressSeconds + deltaTime)
                    if self.progressSeconds >= self.requiredSeconds {
                        self.stopSession()
                        self.onVerificationComplete?()
                    }
                } else {
                    self.statusHeadline = "HAREKET DURDU! SQUAT / ZIPLA!"
                    AlarmSoundEngine.shared.startAlarm()
                }
            }
        } catch {
            updateNoHumanState()
        }
    }

    private func updateNoHumanState() {
        DispatchQueue.main.async {
            self.isHumanDetected = false
            self.isActivelyMoving = false
            self.detectedJointPoints = []
            self.statusHeadline = "İNSAN BEDENİ GÖRÜNMÜYOR! HİLE YOK!"
            AlarmSoundEngine.shared.startAlarm()
        }
    }
}
