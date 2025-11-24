# Student Check-in

## ADDED Requirements

### Requirement: Student Attendance Check-in via Card Scan
The system SHALL allow students to check in for attendance by scanning their student ID card using the mobile app camera.

#### Scenario: Successful card scan check-in
- **WHEN** student opens attendance check-in screen
- **AND** student selects card scan option
- **AND** student scans their student ID card
- **AND** the card is verified successfully
- **THEN** the system records attendance for the current period
- **AND** displays confirmation with check-in time and status (on-time/late)

#### Scenario: Card verification fails
- **WHEN** student scans a card
- **AND** the card cannot be verified
- **THEN** the system displays an error message
- **AND** no attendance record is created

### Requirement: Student Attendance Check-in via Face Scan
The system SHALL allow students to check in for attendance by scanning their face using the mobile app front camera.

#### Scenario: Successful face scan check-in
- **WHEN** student opens attendance check-in screen
- **AND** student selects face scan option
- **AND** student scans their face
- **AND** the face is matched to registered face
- **THEN** the system records attendance for the current period
- **AND** displays confirmation with check-in time and status (on-time/late)

#### Scenario: Face verification fails
- **WHEN** student scans their face
- **AND** the face cannot be matched
- **THEN** the system displays an error message
- **AND** no attendance record is created

### Requirement: Current Period Detection
The system SHALL automatically detect and display the current attendance period based on class configuration and current time.

#### Scenario: Display current period
- **WHEN** student opens check-in screen
- **THEN** the system shows which period (morning/noon/afternoon) is currently active
- **AND** shows the remaining time until period ends

#### Scenario: No active period
- **WHEN** current time is outside all configured periods
- **THEN** the system shows message that no attendance period is currently active
- **AND** check-in is disabled

### Requirement: Late Status Calculation
The system SHALL calculate late status by comparing check-in time against the class's configured period end time.

#### Scenario: On-time check-in
- **WHEN** student checks in before or at the period end time
- **THEN** attendance status is marked as "đúng giờ" (on-time)

#### Scenario: Late check-in
- **WHEN** student checks in after the period end time
- **THEN** attendance status is marked as "trễ" (late)

#### Scenario: Check-in with approved leave
- **WHEN** student has an approved leave permission for the check-in date
- **THEN** attendance status is marked as "vắng phép" (excused absence)
- **AND** the record is not counted as late in statistics

### Requirement: Duplicate Check-in Prevention
The system SHALL prevent duplicate check-ins for the same student, period, and date.

#### Scenario: Attempt duplicate check-in
- **WHEN** student has already checked in for the current period today
- **AND** student attempts to check in again
- **THEN** the system displays existing check-in record
- **AND** no new record is created
