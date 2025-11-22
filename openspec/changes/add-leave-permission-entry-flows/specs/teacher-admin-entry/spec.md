# Teacher/Admin Leave Permission Entry

## ADDED Requirements

### Requirement: Teachers shall be able to manually create leave permissions via web interface

Teachers and administrators accessing the web interface SHALL be able to create leave permission requests on behalf of students (e.g., when parents submit requests via phone or paper forms).

#### Scenario: Teacher creates leave permission for student from admin panel

**Given** a teacher with admin role is logged into the web interface
**When** they navigate to the leave permission management section
**And** they select "Create Leave Permission" or similar action
**Then** a form should be displayed allowing them to:
  - Search and select a student by name or card number
  - View auto-filled student information (name, card, class)
  - Input guardian pickup details (name, CCCD, phone)
  - Select leave date/time and return date/time
  - Select meal deduction dates from generated range
  - Input reason for leave
  - Optionally mark as pre-approved (to bypass approval workflow)

**When** they submit the form with valid data
**Then** a new `XinVePhep` record should be created with:
  - `nguon` set to `NguonVePhep.giaoVienNhap`
  - All student and guardian information properly saved
  - Status set to `choDuyet` OR `daDuyet` based on pre-approval option
  - If pre-approved, `idNguoiDuyet` and `tenNguoiDuyet` should be set to the teacher's ID and name

**And** the teacher should see a success confirmation
**And** the request should appear in the teacher's approval queue (if not pre-approved) or in approved list

#### Scenario: Teacher searches for student by card number

**Given** a teacher is on the leave permission creation form
**When** they enter a student card number in the search field
**Then** the system should find the matching student
**And** auto-fill the student's name, class, and ID
**And** display the student's photo if available

**When** no student is found
**Then** an error message should be displayed
**And** the form should remain empty

#### Scenario: Form validates guardian information

**Given** a teacher is filling out the leave permission form
**When** they input guardian CCCD that is not exactly 12 digits
**Then** a validation error should be displayed
**And** form submission should be prevented

**When** they input guardian phone in invalid Vietnamese format
**Then** a validation error should be displayed
**And** form submission should be prevented

#### Scenario: Pre-approval option bypasses workflow

**Given** a teacher is creating a leave permission
**When** they check the "Pre-approve" option
**And** submit the form
**Then** the request should be created with status `daDuyet`
**And** the teacher's information should be recorded as approver
**And** the request should NOT appear in any approval queue
**And** it should appear in the approved/completed list

### Requirement: Teacher-entered permissions shall be clearly identified

Leave permissions entered by teachers SHALL be distinguishable from student and parent requests throughout the system.

#### Scenario: Detail dialog shows teacher entry source

**Given** a leave permission was created with `nguon = NguonVePhep.giaoVienNhap`
**When** anyone views the request details
**Then** the source section should display "Giáo viên nhập" or "Manually entered by teacher"
**And** it should show the creation timestamp

## MODIFIED Requirements

None - This is a new feature that extends existing functionality without modifying current requirements.

## REMOVED Requirements

None
