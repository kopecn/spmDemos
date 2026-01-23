import Foundation
import FoundationTypes
import FoundationUITools
import SwiftCrossUI
import spmMathTools

struct OTGUIDemoRootView: View {
    // Default values
    private let defaultCurrentPosition: Double = 0.0
    private let defaultCurrentVelocity: Double = 0.0
    private let defaultCurrentAcceleration: Double = 0.0
    private let defaultTargetPosition: Double = 10.0
    private let defaultTargetVelocity: Double = 0.0
    private let defaultTargetAcceleration: Double = 0.0
    private let defaultMaxVelocity: Double = 4.0
    private let defaultMaxAcceleration: Double = 5.0
    private let defaultMaxJerk: Double = 10.0

    // Current state parameters
    @State private var currentPosition: Double = 0.0
    @State private var currentVelocity: Double = 0.0
    @State private var currentAcceleration: Double = 0.0

    // Target state parameters
    @State private var targetPosition: Double = 10.0
    @State private var targetVelocity: Double = 0.0
    @State private var targetAcceleration: Double = 0.0

    // Kinematic limits
    @State private var maxVelocity: Double = 4.0
    @State private var maxAcceleration: Double = 5.0
    @State private var maxJerk: Double = 10.0

    // Status message
    @State private var statusMessage: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Ruckig Trajectory Demo")
                .font(.title)

            // Trajectory visualization
            XUIBaseWaveformChart(
                waveforms: createRuckigTrajectory(),
                labels: ["Position", "Velocity", "Acceleration"],
                colors: [.blue, .green, .red],
                showCursor: true
            )

            // Status indicator
            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundColor(.red)
            }

            // Control panels
            VStack(spacing: 15) {
                Text("Current State").font(.headline)
                sliderControl(
                    label: "Position",
                    value: $currentPosition,
                    range: -10...10,
                    defaultValue: defaultCurrentPosition
                )
                sliderControl(
                    label: "Velocity",
                    value: $currentVelocity,
                    range: -5...5,
                    defaultValue: defaultCurrentVelocity
                )
                sliderControl(
                    label: "Acceleration",
                    value: $currentAcceleration,
                    range: -5...5,
                    defaultValue: defaultCurrentAcceleration
                )

                Text("Target State").font(.headline)
                sliderControl(
                    label: "Position",
                    value: $targetPosition,
                    range: -10...20,
                    defaultValue: defaultTargetPosition
                )
                sliderControl(
                    label: "Velocity",
                    value: $targetVelocity,
                    range: -5...5,
                    defaultValue: defaultTargetVelocity
                )
                sliderControl(
                    label: "Acceleration",
                    value: $targetAcceleration,
                    range: -5...5,
                    defaultValue: defaultTargetAcceleration
                )

                Text("Kinematic Limits").font(.headline)
                sliderControl(
                    label: "Max Velocity",
                    value: $maxVelocity,
                    range: 1...10,
                    defaultValue: defaultMaxVelocity
                )
                sliderControl(
                    label: "Max Acceleration",
                    value: $maxAcceleration,
                    range: 1...10,
                    defaultValue: defaultMaxAcceleration
                )
                sliderControl(label: "Max Jerk", value: $maxJerk, range: 1...20, defaultValue: defaultMaxJerk)
            }
            .padding()
        }
        .padding()
    }

    private func sliderControl(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        defaultValue: Double
    ) -> some View {
        HStack {
            Text("\(label):").frame(width: 120, alignment: .leading)
            Slider(value: value, in: range)
            Text(String(format: "%.2f", value.wrappedValue)).frame(width: 60, alignment: .trailing)
            Button("Reset") {
                value.wrappedValue = defaultValue
            }
            .frame(width: 50)
        }
    }

    private func createRuckigTrajectory() -> [DoubleWaveform1D] {
        // Create Ruckig instance for 1 DOF with 0.01s time step
        let dt = 0.01
        let ruckig = OTG(degreesOfFreedom: 1, deltaTime: dt)

        // Setup input parameters using slider values
        var input = InputParameter(DOFs: 1)

        // Clamp velocity and acceleration values to stay within limits
        let clampedCurrentVelocity = max(-maxVelocity, min(maxVelocity, currentVelocity))
        let clampedTargetVelocity = max(-maxVelocity, min(maxVelocity, targetVelocity))
        let clampedCurrentAcceleration = max(-maxAcceleration, min(maxAcceleration, currentAcceleration))
        let clampedTargetAcceleration = max(-maxAcceleration, min(maxAcceleration, targetAcceleration))

        // Current state from sliders
        input.currentPosition = [currentPosition]
        input.currentVelocity = [clampedCurrentVelocity]
        input.currentAcceleration = [clampedCurrentAcceleration]

        // Target state from sliders
        input.targetPosition = [targetPosition]
        input.targetVelocity = [clampedTargetVelocity]
        input.targetAcceleration = [clampedTargetAcceleration]

        // Kinematic limits from sliders
        input.maxVelocity = [maxVelocity]
        input.maxAcceleration = [maxAcceleration]
        input.maxJerk = [maxJerk]

        print("\n" + String(repeating: "=", count: 80))
        print("🚀 TRAJECTORY CALCULATION START")
        print(String(repeating: "=", count: 80))
        print("Trajectory parameters:")
        print("  Current: pos=\(currentPosition), vel=\(clampedCurrentVelocity), acc=\(clampedCurrentAcceleration)")
        print("  Target:  pos=\(targetPosition), vel=\(clampedTargetVelocity), acc=\(clampedTargetAcceleration)")
        print("  Limits:  maxVel=±\(maxVelocity), maxAcc=±\(maxAcceleration), maxJerk=±\(maxJerk)")
        print(String(repeating: "-", count: 80))

        // Validate input
        do {
            try input.validate(
                checkCurrentStateWithinLimits: false,
                checkTargetStateWithinLimits: true
            )
        } catch let error as RuckigError {
            print("Validation error: \(error.message)")
            statusMessage = "Error: \(error.message)"
            return createEmptyWaveforms(dt: dt)
        } catch {
            print("Validation error: \(error)")
            statusMessage = "Validation error"
            return createEmptyWaveforms(dt: dt)
        }

        // Calculate trajectory
        var trajectory = Trajectory(dofs: 1)
        let result = ruckig.calculate(input: input, trajectory: &trajectory)

        guard result == .Working || result == .Finished else {
            print("Calculation failed with result: \(result)")
            statusMessage = "Calculation failed: \(result)"
            return createEmptyWaveforms(dt: dt)
        }

        // Clear status on success
        statusMessage = ""

        print(String(repeating: "-", count: 80))
        print("✓ Trajectory calculation successful")
        print("  Duration: \(String(format: "%.6f", trajectory.getDuration()))s")

        // Report the 7 time intervals for the first DOF
        let timeIntervals = trajectory.getProfiles()[0][0].t
        print("  Time Intervals: [", terminator: "")
        for (index, interval) in timeIntervals.enumerated() {
            if index > 0 { print(", ", terminator: "") }
            print(String(format: "%.6f", interval), terminator: "")
        }
        print("]s")

        print(String(repeating: "=", count: 80) + "\n")

        // Sample the trajectory
        let duration = trajectory.getDuration()

        // Ensure duration is valid and reasonable
        guard duration > 0 && duration.isFinite else {
            print("Invalid trajectory duration: \(duration)")
            return createEmptyWaveforms(dt: dt)
        }

        let sampleCount = Int(duration / dt) + 1

        var positionValues: [Double] = []
        var velocityValues: [Double] = []
        var accelerationValues: [Double] = []

        for i in 0..<sampleCount {
            let t = Double(i) * dt
            let (pos, vel, acc) = trajectory.atTime(t)

            // Safety check for array access
            guard pos.count > 0, vel.count > 0, acc.count > 0 else {
                print("Invalid trajectory state at t=\(t)")
                return createEmptyWaveforms(dt: dt)
            }

            positionValues.append(pos[0])
            velocityValues.append(vel[0])
            accelerationValues.append(acc[0])
        }

        return [
            DoubleWaveform1D(values: positionValues, dt: PrecisionTimeInterval(seconds: dt)),
            DoubleWaveform1D(values: velocityValues, dt: PrecisionTimeInterval(seconds: dt)),
            DoubleWaveform1D(values: accelerationValues, dt: PrecisionTimeInterval(seconds: dt)),
        ]
    }

    private func createEmptyWaveforms(dt: Double) -> [DoubleWaveform1D] {
        // Return waveforms with at least one zero value to prevent UI crashes
        // when trying to access empty arrays
        return [
            DoubleWaveform1D(values: [0.0], dt: PrecisionTimeInterval(seconds: dt)),
            DoubleWaveform1D(values: [0.0], dt: PrecisionTimeInterval(seconds: dt)),
            DoubleWaveform1D(values: [0.0], dt: PrecisionTimeInterval(seconds: dt)),
        ]
    }
}
