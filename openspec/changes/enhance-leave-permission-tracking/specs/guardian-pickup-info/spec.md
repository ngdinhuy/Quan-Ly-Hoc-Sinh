# Guardian Pickup Information for Leave Permission System

## ADDED Requirements

### Requirement: Capture guardian pickup details in new leave permission system
When a student requests formal leave permission (xin về phép) through the new system, the system SHALL capture the details of the person who will pick up the student to ensure safety and accountability.

**Note:** This is for the new `xin_ve_phep` system only, not the existing `xin_ra_vao` system.

#### Scenario: Student submits leave permission with guardian information
**Given** a student is creating a leave permission request via "Xin Về Phép" screen
**When** they fill out the leave permission form
**Then** they MUST provide:
- Guardian's full name (`ten_nguoi_don`) - minimum 3 characters
- Guardian's citizen ID number / CCCD (`cccd_nguoi_don`) - exactly 12 digits
- Guardian's phone number (`sdt_nguoi_don`) - valid Vietnamese phone format
**And** all three fields are required and cannot be empty

#### Scenario: Parent submits leave permission for their child
**Given** a parent is creating a leave permission request for their child
**When** they fill out the leave permission form
**Then** the guardian information fields default to the parent's information
**And** they can edit any of the guardian fields
**And** all validation rules still apply
**And** the system records the parent's ID in `id_phu_huynh` field
**And** the system records the parent's name in `ten_phu_huynh` field

#### Scenario: Teacher creates leave permission on behalf of student
**Given** a teacher is manually creating a leave permission for a student
**When** they fill out the request form
**Then** they MUST enter all guardian pickup information (name, CCCD, phone number)
**And** the form validates that all fields are properly filled

#### Scenario: Viewing leave request displays guardian information
**Given** a leave request has been submitted with guardian details
**When** a teacher or admin views the leave request
**Then** the guardian's name, CCCD, and phone number are clearly displayed
**And** the information is formatted for easy reading

#### Scenario: Guardian phone number validation
**Given** a user is entering guardian phone number
**When** they submit the form
**Then** the system validates the phone number format (Vietnamese phone format)
**And** shows an error if the format is invalid

#### Scenario: CCCD number validation
**Given** a user is entering guardian CCCD
**When** they submit the form
**Then** the system validates the CCCD is a 12-digit number
**And** shows an error if the format is invalid

#### Scenario: Parent information is stored when parent creates request
**Given** a parent logs into the system with their parent account
**When** they submit a leave permission request for their child
**Then** the system SHALL store the parent's ID in `id_phu_huynh`
**And** the system SHALL store the parent's full name in `ten_phu_huynh`
**And** this information is used for audit trail and contact purposes

#### Scenario: Student submission does not include parent information
**Given** a student logs into the system with their student account
**When** they submit a leave permission request
**Then** the `id_phu_huynh` field SHALL be null
**And** the `ten_phu_huynh` field SHALL be null
**And** only the guardian pickup information is required

#### Scenario: Viewing request shows who submitted it
**Given** a leave permission request exists in the system
**When** a teacher views the request details
**Then** the system displays the request source (`nguon`)
**And** if submitted by parent (`appPhuHuynh`), shows the parent's name from `ten_phu_huynh`
**And** if submitted by student (`appHocSinh`), shows "Học sinh tự nộp"
**And** if entered by teacher (`giaoVienNhap`), shows "Giáo viên nhập"
