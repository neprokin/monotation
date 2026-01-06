//
//  HapticFeedback.swift
//  monotation
//
//  Manages haptic feedback using Core Haptics for meditation app
//

import CoreHaptics
import SwiftUI
import AVFoundation
import Combine

@MainActor
class HapticFeedback: ObservableObject {
    static let shared = HapticFeedback()
    
    private var engine: CHHapticEngine?
    @Published var isSupported: Bool = false
    
    // Settings
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticIntensity") private var intensityMultiplier = 1.0  // 0.5 - 1.0
    
    private init() {
        prepareHaptics()
        prepareAudio()
    }
    
    // MARK: - Setup
    
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("⚠️ Device doesn't support haptics")
            return
        }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            isSupported = true
            
            // Auto-restart on failure
            engine?.resetHandler = { [weak self] in
                print("🔄 Haptic engine reset")
                try? self?.engine?.start()
            }
            
            // Handle interruptions (e.g., phone call)
            engine?.stoppedHandler = { reason in
                print("⏸️ Haptic engine stopped: \(reason)")
            }
            
            print("✅ Haptic engine initialized")
        } catch {
            print("❌ Haptic engine creation error: \(error)")
        }
    }
    
    private func prepareAudio() {
        do {
            // Configure audio session for meditation sounds
            // .playback + .mixWithOthers allows sound to play in background and with other audio
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers, .duckOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Audio session setup error: \(error)")
        }
    }
    
    // MARK: - Meditation Haptics & Sounds
    
    /// Мягкое подтверждение старта медитации (после обратного отсчета)
    func playMeditationStart() {
        guard hapticsEnabled else { return }
        
        // Sound: тихий "тик"
        if soundEnabled {
            AudioServicesPlaySystemSound(1104) // SMS_Alert_Popcorn.caf - короткий, тихий
        }
        
        // Haptic: мягкая, короткая вибрация
        let intensity = 0.5 * intensityMultiplier
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)  // Мягкая
            ],
            relativeTime: 0
        )
        
        playPattern([event])
    }
    
    /// Настойчивое уведомление о завершении медитации
    func playMeditationCompletion() {
        // Sound: короткий системный звук (для повторения каждую секунду)
        if soundEnabled {
            AudioServicesPlaySystemSound(1013) // SMSReceived_Classic.caf - короткий, классический
        }
        
        guard hapticsEnabled else { return }
        
        // Haptic: серия из 3 нарастающих импульсов + продолжительный резонанс
        let baseIntensity = intensityMultiplier
        let events: [CHHapticEvent] = [
            // Первый импульс (мягкий)
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.6 * baseIntensity)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                ],
                relativeTime: 0
            ),
            
            // Второй импульс (средний)
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.75 * baseIntensity)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0.15
            ),
            
            // Третий импульс (сильный)
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.9 * baseIntensity)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0.3
            ),
            
            // Продолжительный резонанс (затухающий)
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(0.6 * baseIntensity)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.35,
                duration: 1.0
            )
        ]
        
        // Параметр затухания для continuous event
        let fadeParameter = CHHapticParameterCurve(
            parameterID: .hapticIntensityControl,
            controlPoints: [
                CHHapticParameterCurve.ControlPoint(relativeTime: 0, value: 1.0),
                CHHapticParameterCurve.ControlPoint(relativeTime: 1.0, value: 0.0)
            ],
            relativeTime: 0.35
        )
        
        playPattern(events, parameterCurves: [fadeParameter])
    }
    
    /// Мягкий интервальный сигнал (опционально, для будущего)
    func playIntervalSignal() {
        guard hapticsEnabled else { return }
        
        let intensity = 0.3 * intensityMultiplier
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)  // Очень мягкая
            ],
            relativeTime: 0
        )
        
        playPattern([event])
    }
    
    // MARK: - Playback
    
    private func playPattern(_ events: [CHHapticEvent], parameterCurves: [CHHapticParameterCurve] = []) {
        guard let engine = engine else { return }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameterCurves: parameterCurves)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("❌ Haptic playback error: \(error)")
        }
    }
    
    // MARK: - Fallback Haptics (for older devices without Core Haptics)
    
    /// Simple haptic using UIFeedbackGenerator (fallback)
    func playSimpleImpact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard hapticsEnabled else { return }
        
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

