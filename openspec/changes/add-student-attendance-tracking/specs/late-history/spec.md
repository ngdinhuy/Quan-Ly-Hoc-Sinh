# Late History Viewing

## ADDED Requirements

### Requirement: Homeroom Teacher Late History Access
The system SHALL allow homeroom teachers to view late arrival history for students in their assigned class.

#### Scenario: Teacher views late history
- **WHEN** homeroom teacher opens late history screen
- **THEN** the system displays late records for their homeroom class only
- **AND** records are filterable by date range
- **AND** each record shows: student name, date, period, check-in time

#### Scenario: Teacher filters by date range
- **WHEN** teacher selects start and end dates
- **THEN** only late records within the date range are displayed
- **AND** records are sorted by date descending

#### Scenario: No late records
- **WHEN** no students in the class have late records in the selected period
- **THEN** the system displays an empty state message

### Requirement: Parent Late History Access
The system SHALL allow parents to view late arrival history for their linked child.

#### Scenario: Parent views child's late history
- **WHEN** parent opens late history screen
- **THEN** the system displays late records for their linked child only
- **AND** records are filterable by date range
- **AND** each record shows: date, period, check-in time

#### Scenario: Parent filters by date range
- **WHEN** parent selects start and end dates
- **THEN** only late records within the date range are displayed
- **AND** records are sorted by date descending

#### Scenario: Parent with no linked child
- **WHEN** parent account has no linked student
- **THEN** the system displays a message that no student is linked
- **AND** no attendance data is shown

### Requirement: Excused Absences Distinction
The system SHALL clearly distinguish between late arrivals and excused absences in history views.

#### Scenario: Display excused vs late
- **WHEN** viewing attendance history
- **THEN** excused absences (vắng phép) are shown with different visual styling
- **AND** excused absences are not counted in late summaries
