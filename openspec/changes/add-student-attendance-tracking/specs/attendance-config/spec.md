# Attendance Configuration

## ADDED Requirements

### Requirement: Attendance Time Period Configuration
The system SHALL allow administrators to configure attendance time periods (morning, noon, afternoon/evening) for each class for each day of the week via web admin interface. Configuration is stored as an embedded map in the class (`lop`) document.

#### Scenario: Admin configures attendance periods for a class
- **WHEN** admin selects a class and weekday
- **THEN** the system displays time period inputs for morning (sáng), noon (trưa), and afternoon/evening (chiều tối)
- **AND** each period has start time and end time fields in HH:mm format
- **AND** admin can save the configuration

#### Scenario: Admin copies configuration from another day
- **WHEN** admin wants to apply same times across multiple days
- **THEN** admin can copy configuration from one weekday to another
- **AND** the copied configuration is saved independently

#### Scenario: Default configuration when none exists
- **WHEN** a class has no attendance configuration for a weekday
- **THEN** the system uses default time periods:
  - Morning: 07:00 - 07:30
  - Noon: 13:00 - 13:30
  - Afternoon/evening: 19:00 - 19:30

### Requirement: Per-Class Per-Weekday Configuration
The system SHALL store attendance configuration separately for each class and each day of the week.

#### Scenario: Different times for different days
- **WHEN** admin sets Monday morning period to 07:00-07:30
- **AND** admin sets Tuesday morning period to 07:15-07:45
- **THEN** each day's configuration is stored and applied independently

#### Scenario: Different times for different classes
- **WHEN** Class A has morning period 07:00-07:30
- **AND** Class B has morning period 07:30-08:00
- **THEN** each class uses its own configuration for late calculation
