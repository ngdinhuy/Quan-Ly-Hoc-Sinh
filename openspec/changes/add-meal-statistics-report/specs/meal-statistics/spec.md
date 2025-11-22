# Meal Statistics Report

## ADDED Requirements

### Requirement: View daily meal statistics by class
The system SHALL provide admin users with a screen to view meal statistics for each class on a selected date, showing total students, students with meal deduction, and students eating.

#### Scenario: Admin views meal statistics for a specific date
- **GIVEN** admin is on the meal statistics screen
- **WHEN** admin selects a date (default: today)
- **THEN** the system displays a table with columns: Lớp, Tổng HS, Cắt cơm, Ăn cơm
- **AND** each row shows one class with its meal statistics
- **AND** only approved leave permissions (`daDuyet`) are counted
- **AND** meal deduction is counted from `danh_sach_ngay_cat_com` containing the selected date

#### Scenario: Calculate meal statistics correctly
- **GIVEN** Class 10A has 30 students total
- **AND** 5 students have approved leave permissions with meal deduction on the selected date
- **WHEN** admin views statistics for that date
- **THEN** the row for 10A shows: Tổng HS = 30, Cắt cơm = 5, Ăn cơm = 25

#### Scenario: No meal deductions for a class
- **GIVEN** Class 10B has 28 students
- **AND** no approved leave permissions have meal deduction on the selected date
- **WHEN** admin views statistics for that date
- **THEN** the row for 10B shows: Tổng HS = 28, Cắt cơm = 0, Ăn cơm = 28

#### Scenario: Display summary totals
- **GIVEN** admin is viewing meal statistics
- **WHEN** the table is displayed
- **THEN** the system shows a summary row at the bottom
- **AND** summary shows: Tổng cộng all classes, Total cắt cơm, Total ăn cơm

### Requirement: View monthly meal statistics overview
The system SHALL allow admin to select a month/year to view meal statistics for all days in that month.

#### Scenario: Admin selects month to view overview
- **GIVEN** admin is on the meal statistics screen
- **WHEN** admin selects a month and year
- **THEN** the system displays a calendar or table view showing meal deduction counts for each day
- **AND** admin can click on any day to see detailed class breakdown

#### Scenario: Monthly summary statistics
- **GIVEN** admin has selected November 2025
- **WHEN** viewing monthly overview
- **THEN** the system shows total meal deductions for the entire month
- **AND** shows average daily meal deductions

### Requirement: Export meal statistics to Excel
The system SHALL provide an export function to download meal statistics as an Excel file.

#### Scenario: Export daily statistics to Excel
- **GIVEN** admin is viewing meal statistics for a specific date
- **WHEN** admin clicks the "Xuất Excel" button
- **THEN** the system generates an Excel file with the current table data
- **AND** file includes: date, class list with statistics, summary totals
- **AND** file is downloaded with name format: `thong_ke_xuat_an_YYYY-MM-DD.xlsx`

#### Scenario: Export monthly statistics to Excel
- **GIVEN** admin is viewing monthly overview
- **WHEN** admin clicks the "Xuất Excel" button
- **THEN** the system generates an Excel file with all days in the month
- **AND** each row represents a day with total deductions across all classes
- **AND** file is downloaded with name format: `thong_ke_xuat_an_thang_MM-YYYY.xlsx`

### Requirement: Filter statistics by class
The system SHALL allow admin to filter meal statistics by specific class or view all classes.

#### Scenario: Filter by single class
- **GIVEN** admin is viewing meal statistics
- **WHEN** admin selects a specific class from the filter dropdown
- **THEN** the table shows only that class's statistics
- **AND** export includes only the filtered data

#### Scenario: View all classes (default)
- **GIVEN** admin opens meal statistics screen
- **WHEN** no filter is applied
- **THEN** the table shows all classes sorted by class name
- **AND** summary row includes all classes
