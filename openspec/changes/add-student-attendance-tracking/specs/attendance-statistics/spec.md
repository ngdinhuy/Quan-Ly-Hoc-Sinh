# Attendance Statistics

## ADDED Requirements

### Requirement: Admin Late Arrival Statistics
The system SHALL provide administrators with statistics on late arrivals by class and date via web admin interface.

#### Scenario: View daily late statistics by class
- **WHEN** admin opens late statistics screen
- **AND** admin selects a date
- **THEN** the system displays a table with columns: class name, total students, late count, late percentage
- **AND** data is grouped by class

#### Scenario: Filter by specific class
- **WHEN** admin selects a class from dropdown
- **THEN** only statistics for the selected class are displayed

#### Scenario: View late student details
- **WHEN** admin clicks on a class row in the statistics table
- **THEN** the system shows a list of late students for that class on the selected date
- **AND** list includes: student name, period, check-in time

### Requirement: Export Late Statistics to Excel
The system SHALL allow administrators to export late arrival statistics to Excel format.

#### Scenario: Export daily statistics
- **WHEN** admin clicks export button on daily view
- **THEN** the system generates an Excel file with:
  - Date header
  - Class-by-class breakdown with columns: class, total students, late count, on-time count
  - Total summary row
- **AND** file downloads with naming convention: `thong_ke_di_muon_YYYY-MM-DD.xlsx`

### Requirement: Leave Permission Integration in Statistics
The system SHALL exclude students with approved leave permissions from late calculations in statistics.

#### Scenario: Student on leave not counted as late
- **WHEN** calculating late statistics for a date
- **AND** a student has approved leave permission for that date
- **THEN** the student is excluded from both late count and total count
- **AND** the student appears in "vắng phép" category if displayed

#### Scenario: Statistics accuracy with mixed attendance
- **WHEN** a class has 30 students
- **AND** 5 students have approved leave
- **AND** 3 of the remaining 25 students are late
- **THEN** statistics show: total=25, late=3, late percentage=12%
