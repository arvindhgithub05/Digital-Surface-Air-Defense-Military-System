# Digital-Surface-Air-Defense-Military-System

✅ List of Required Verilog Modules (In Integration Order)

# 1. 🧭 Module Name: coord_parser.v
✅ Objectives

The objective of the coord_parser module is to:

Accept incoming raw coordinate data (e.g., from radar or sensor system).

Extract (X, Y, Z) values from the input stream.

Validate that both X, Y and Z are present.

Output a data valid signal to the next module in the pipeline (e.g., cleaner).

🎯 Purpose of Use

This module acts as a data decoder and front-end formatter:

It converts an incoming serial/parallel stream of coordinates into clean, synchronized X-Y pairs.

Ensures data handshaking using data_valid and data_ready.

Acts as a safety gate so only complete and meaningful data is passed onward.

# 2. 🧭 Module: coord_cleaner.v
✅ Objectives

To filter out noisy or jittery target coordinates that might arise from sensor glitches, radar flicker, or false hits.

To implement a basic denoising logic: e.g., pass data only if the current coordinate is not significantly different from the last one (within a predefined threshold).

Maintain valid/ready handshake logic to safely forward clean data to the next module (e.g., target acquisition).

🎯 Purpose of Use

In real defense hardware (like radar or missile sensors), raw coordinates often jitter slightly due to environment or noise. We don’t want to pass these minor fluctuations to the lock logic — we want stable signals that reflect real motion.

🔐 Design Assumptions

Coordinate values are 16-bit signed or unsigned (we treat them as unsigned for now)

Thresholds for noise are programmable or fixed constants (e.g., max difference of 4 units in either axis)

If data is noisy (too jumpy), discard and wait for next

# 3. 🧭 Module: target_acq.v
✅ Objectives

The Target Acquisition module is responsible for:

Detecting the presence of a real target from the stream of cleaned coordinates.

Observing if coordinates remain stable over time (noisy blips are rejected).

Once stable movement is confirmed for a few consecutive inputs, it asserts a target_found signal.

All of this while maintaining valid/ready handshake protocol.

🎯 Purpose of Use

This is the decision-making core that decides when the system has identified a valid, trackable object.

It:

Avoids locking onto false positives

Asserts target_found when criteria are met

Forwards the same X, Y data along with the acquisition status

🔐 Design Assumptions

A target is considered valid if coordinates remain within small movement range for N consecutive samples (you can tune N).

Coordinates are treated as unsigned 16-bit.

Coordinate input is already filtered (from coord_cleaner.v), so this logic is responsible for verifying consistency.

Downstream logic (lock FSM) consumes output when data_out_valid is asserted.

# 4. 🧭 Module: lock_fsm.v
✅ Objectives

This module implements a Finite State Machine (FSM) that:

Waits in IDLE state until a valid target is found.

Transitions through ACQUIRE, VERIFY, LOCKED, and LOST states.

Ensures lock is not granted too early (needs reconfirmation in VERIFY).

Detects target loss if output is missing/stale beyond a timeout window.

🎯 Purpose in Defense Pipeline

In defense-grade systems (e.g., missile guidance, turret tracking):

You cannot afford false locks or random state transitions.

This FSM ensures controlled acquisition and safe unlocking if tracking fails.

Output lock_active can drive actuators or fire-control computers.

🔐 Design Assumptions

target_found signal comes from target_acq.v

FSM waits in IDLE, watches for target_found to go high

Once locked, expects fresh coordinates regularly

If data_valid stalls too long, transitions to LOST

Timeout is implemented with a counter

# 5. 🧭 Module: tracker_core.v
Once the FSM asserts lock_active, this module:

Begins tracking the target continuously

Calculates a simple velocity estimate (delta X/Y/Z)

Performs linear motion prediction one or more steps ahead

Outputs both:

Current cleaned coordinates, and

Projected next coordinates based on velocity

Ensures data safety using valid/ready protocol

🎯 Purpose of Use

In real defense systems:

You must predict ahead due to actuation delays (motors, turrets, missiles)

You must monitor velocity to counter high-speed or erratic motion

You must maintain precision while staying robust to small movements

🔐 Design Assumptions

Tracking occurs only when lock_active == 1

Input coordinate stream is cleaned, stable, and valid

Output includes:

Real-time X/Y/Z

Predicted X/Y/Z

Target moving flag (based on velocity threshold)

# 6. 🧭 Module: fire_ctrl.v
✅ Objectives

The fire_ctrl.v module is the fire control unit — a decision-making block that:

Monitors predicted vs actual positions

Confirms target is locked and not erratic

Fires only when:

Target is within a strike window

It’s not oscillating or moving too fast

System confirms high hit probability

Generates a single-cycle pulse: fire_pulse

🎯 Purpose in Defense Use

This module mimics what real-world fire-control systems do:

Waits for lock and stability

Checks that predicted and current coordinates converge (suggesting the target isn’t dodging)

Asserts fire_pulse to trigger actuators (missiles, lasers, turrets, etc.)

🔐 Design Assumptions

Strike window = max distance allowed between x_pred and x_curr (and same for y and z)

Uses a window threshold parameter

Fires once and waits for next valid lock + prediction match

Accepts lock_active, predicted & current coords, target_moving

