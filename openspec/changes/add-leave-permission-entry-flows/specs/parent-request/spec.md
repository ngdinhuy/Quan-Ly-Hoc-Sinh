# Parent Leave Permission Request

## ADDED Requirements

### Requirement: Parents shall be able to request leave permissions for their children

Parents using the mobile app SHALL be able to submit leave permission requests for their linked child with guardian information auto-filled from their profile.

#### Scenario: Parent navigates to leave permission request form

**Given** a parent is logged into the mobile app
**And** they are on the main parent screen
**When** they tap on "Xin Về Phép" or "Request Leave" action
**Then** they should be navigated to a leave permission request form
**And** student information should be auto-filled from their linked child
  - Student name
  - Student card number
  - Student class
**And** guardian information should be auto-filled from their `PhuHuynh` profile:
  - Guardian name (from `hoTen`)
  - Guardian CCCD (from `soCccd`)
  - Guardian phone (from `soDienThoai`)

#### Scenario: Parent submits leave permission request

**Given** a parent is on the leave permission request form
**And** student and guardian information is auto-filled
**When** they select leave date and time
**And** optionally select return date and time
**And** review/modify the auto-generated meal deduction dates
**And** input the reason for leave
**And** tap "Submit" or "Gửi yêu cầu"
**Then** a new `XinVePhep` record should be created with:
  - `nguon` set to `NguonVePhep.appPhuHuynh`
  - `tenPhuHuynh` set to the parent's name for tracking
  - `idHocSinh` set to the child's ID
  - Student information from the child's record
  - Guardian information from the parent's profile
  - Status set to `choDuyet` (pending approval)

**And** the parent should see a success confirmation
**And** the parent should be navigated back to the main screen or history view

#### Scenario: Parent views their submitted leave requests

**Given** a parent is logged into the mobile app
**When** they navigate to "Lịch Sử Về Phép" or "Leave History" section
**Then** they should see all leave permission requests for their child
**And** requests submitted by them should show source as "Phụ huynh: [parent name]"
**And** requests submitted by the student should show source as "Học sinh tự nộp"

#### Scenario: Parent can modify guardian contact before submission

**Given** a parent is on the leave permission request form
**And** guardian phone number is auto-filled from their profile
**When** they change the phone number to an alternate contact
**And** the alternate phone is in valid Vietnamese format
**And** they submit the request
**Then** the request should be created with the modified phone number
**And** the parent's profile phone number should remain unchanged

**When** they change the phone to an invalid format
**Then** validation should prevent submission
**And** an error message should be displayed

#### Scenario: Parent cannot submit if child information is missing

**Given** a parent is logged into the app
**But** their `PhuHuynh` profile does not have a valid `idHs` (linked child)
**When** they attempt to access the leave permission request form
**Then** an error message should be displayed
**And** they should not be able to proceed
**And** they should be guided to contact administration

### Requirement: Parent-submitted requests shall be clearly identified

Leave permissions submitted by parents SHALL be distinguishable from student and teacher-entered requests.

#### Scenario: Detail dialog shows parent submission source

**Given** a leave permission was created with `nguon = NguonVePhep.appPhuHuynh`
**And** `tenPhuHuynh` contains the parent's name
**When** anyone views the request details
**Then** the source section should display "Phụ huynh: [parent name]"
**And** it should show the creation timestamp

## MODIFIED Requirements

None - This is a new feature that extends existing functionality without modifying current requirements.

## REMOVED Requirements

None
