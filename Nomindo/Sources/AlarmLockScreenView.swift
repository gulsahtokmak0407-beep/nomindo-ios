import SwiftUI

struct AlarmLockScreenView: View {
    @EnvironmentObject var alarmManager: AlarmManager
    @StateObject private var poseEngine = PoseVerificationEngine()
    @State private var showCameraVerification = false
    @State private var shakeOffset: CGFloat = 0

    var body: some View {
        ZStack {
            Color(red: 0.04, green: 0.04, blue: 0.06)
                .ignoresSafeArea()

            if !showCameraVerification {
                // PHASE 1: RELENTLESS WRITTEN PRESSURE & ALARM LOOP
                VStack(spacing: 28) {
                    Spacer()

                    HStack(spacing: 8) {
                        Image(systemName: "bell.and.waves.left.and.right.fill")
                            .foregroundColor(.orange)
                        Text("NOMINDO ALARM AKTİF")
                            .font(.caption.bold())
                            .tracking(2)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())

                    Text(alarmManager.activeAlarmLabel.uppercased())
                        .font(.title3.bold())
                        .foregroundColor(.gray)

                    Text(alarmManager.currentPressureMessage)
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .offset(x: shakeOffset)

                    if alarmManager.dismissAttemptCount > 0 {
                        Text("KAPATMA DENEMESİ: \(alarmManager.dismissAttemptCount) • KAÇIŞ YOK!")
                            .font(.footnote.bold())
                            .foregroundColor(.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.red.opacity(0.18))
                            .cornerRadius(8)
                    }

                    Spacer()

                    // Fake dismiss button that triggers escalating written motivation
                    Button(action: {
                        alarmManager.registerDismissAttempt()
                        triggerShake()
                    }) {
                        Text("ALARMI KAPAT")
                            .font(.headline.bold())
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)

                    // Real verification button
                    Button(action: {
                        showCameraVerification = true
                        poseEngine.onVerificationComplete = {
                            alarmManager.completeVerification()
                        }
                        poseEngine.startSession()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "camera.viewfinder")
                                .font(.title2.bold())
                            Text("KAMERAYI AÇ VE SPORU KANITLA")
                                .font(.headline.bold())
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color(red: 1.0, green: 0.25, blue: 0.1)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .orange.opacity(0.45), radius: 12, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
                }
            } else {
                // PHASE 2: STRICT AI CAMERA VERIFICATION
                ZStack {
                    if let errorMsg = poseEngine.cameraErrorMessage {
                        VStack(spacing: 24) {
                            Image(systemName: "video.slash.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.red)

                            Text(errorMsg)
                                .font(.title3.bold())
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)

                            Button("TEKRAR DENE") {
                                poseEngine.startSession()
                            }
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(Color.orange)
                            .cornerRadius(14)
                        }
                    } else {
                        CameraPreviewRepresentable(session: poseEngine.captureSession)
                            .ignoresSafeArea()

                        SkeletonOverlayView(
                            points: poseEngine.detectedJointPoints,
                            isMoving: poseEngine.isActivelyMoving
                        )
                        .ignoresSafeArea()

                        VStack {
                            // Top HUD
                            VStack(spacing: 8) {
                                Text(poseEngine.statusHeadline)
                                    .font(.headline.bold())
                                    .foregroundColor(poseEngine.isActivelyMoving ? .green : .orange)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.black.opacity(0.8))
                                    .cornerRadius(12)

                                Text(alarmManager.currentPressureMessage)
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.red.opacity(0.75))
                                    .cornerRadius(8)
                            }
                            .padding(.top, 56)

                            Spacer()

                            // Bottom 30-second AI Progress Bar
                            VStack(spacing: 12) {
                                HStack {
                                    Text("YAPAY ZEKA HAREKET DOĞRULAMASI")
                                        .font(.caption.bold())
                                        .foregroundColor(.white.opacity(0.85))
                                    Spacer()
                                    Text("\(Int(poseEngine.progressSeconds)) / 30 SN")
                                        .font(.headline.bold())
                                        .foregroundColor(.orange)
                                }

                                GeometryReader { barGeo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color.white.opacity(0.2))
                                            .frame(height: 18)

                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(poseEngine.isActivelyMoving ? Color.green : Color.orange)
                                            .frame(
                                                width: barGeo.size.width * CGFloat(poseEngine.progressSeconds / poseEngine.requiredSeconds),
                                                height: 18
                                            )
                                            .animation(.linear(duration: 0.15), value: poseEngine.progressSeconds)
                                    }
                                }
                                .frame(height: 18)
                            }
                            .padding(20)
                            .background(Color.black.opacity(0.85))
                            .cornerRadius(20)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 36)
                        }
                    }
                }
            }
        }
        .onDisappear {
            poseEngine.stopSession()
        }
    }

    private func triggerShake() {
        withAnimation(.default) { shakeOffset = -14 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.default) { shakeOffset = 14 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.default) { shakeOffset = 0 }
        }
    }
}
