# Absence Statistics

## ADDED Requirements

### Requirement: Absence Detection
The system SHALL identify students who are absent (not checked in and not on leave) for each attendance period.

#### Scenario: Calculate absent students for ended period
- **WHEN** calculating statistics for a class and date
- **AND** the attendance period has ended (current time > period end + 30 min)
- **THEN** the system identifies absent students as: all students - checked in students - students on leave
- **AND** each absent student is counted once per missed period

#### Scenario: Period not yet ended
- **WHEN** calculating statistics for a period that hasn't ended
- **THEN** absence count shows as not applicable
- **AND** system does not count students as absent for that period

### Requirement: Admin Absence Statistics Display
The system SHALL display absence statistics alongside late arrival statistics in the admin dashboard.

#### Scenario: View combined attendance statistics
- **WHEN** admin opens attendance statistics screen
- **AND** admin selects a date
- **THEN** the system displays a table with columns: class, total students, on-time count, late count, absent count
- **AND** summary cards show totals for each category

#### Scenario: View absent student details
- **WHEN** admin clicks detail button for a class
- **THEN** the system shows a dialog with tabs for late students and absent students
- **AND** absent students list shows: student name, missed period(s)

### Requirement: Parent Absence History Access
The system SHALL allow parents to view absence history for their linked child.

#### Scenario: Parent views child's absence history
- **WHEN** parent opens absence history screen
- **THEN** the system displays absences for their linked child
- **AND** records are filterable by date range
- **AND** each record shows: date, missed period

#### Scenario: No absences
- **WHEN** child has no absence records in selected period
- **THEN** the system displays an empty state message
- **AND** indicates child has perfect attendance for the period

### Requirement: Absence Navigation from Parent Main Screen
The system SHALL provide navigation to absence history from parent main screen.

#### Scenario: Navigate to absence history
- **WHEN** parent is on main screen
- **THEN** an action card "Lịch Sử Vắng Mặt" is visible
- **AND** tapping the card navigates to absence history screen
