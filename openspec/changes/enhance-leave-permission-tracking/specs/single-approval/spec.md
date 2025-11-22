# Single-Level Approval Workflow for Leave Permission System

## ADDED Requirements

### Requirement: Implement single-level approval for new leave permission system
Leave permission requests in the new `xin_ve_phep` system SHALL be approved by ONE teacher (either duty teacher or homeroom teacher) to streamline the approval process while maintaining proper oversight.

**Note:** This is for the new `xin_ve_phep` system only. The existing `xin_ra_vao` system remains unchanged with its current approval workflow.

**Related to**: `guardian-pickup-info`, `meal-deduction-tracking`

#### Scenario: Teacher approves leave permission
**Given** a leave permission is in `choDuyet` (waiting for approval) status
**When** a teacher (duty teacher or homeroom teacher) reviews and approves it via "Duyệt Về Phép" screen
**Then** the system records the approving teacher's ID in `id_nguoi_duyet`
**And** the system records the approving teacher's name in `ten_nguoi_duyet`
**And** the system records the approval timestamp in `thoi_gian_duyet`
**And** the status changes to `daDuyet` (approved)
**And** the student can proceed with the leave

#### Scenario: Teacher rejects leave permission
**Given** a leave permission is in `choDuyet` status
**When** the teacher rejects it with a reason
**Then** the system records the rejection reason in `ly_do_tu_choi`
**And** the system records the rejecting teacher's ID in `id_nguoi_duyet`
**And** the status changes to `tuChoi` (rejected)
**And** the request cannot proceed

#### Scenario: Viewing approval information in leave request details
**Given** a leave request has been approved
**When** viewing the request details (by student, parent, or teacher)
**Then** the approver information is displayed with label "Giáo viên duyệt" (Approving teacher)
**And** the approver's name is shown from `ten_nguoi_duyet`
**And** the approval timestamp is shown from `thoi_gian_duyet`

#### Scenario: Leave permission status shows approval state
**Given** a leave permission exists in the system
**When** viewing the request list (student history, teacher approval screens)
**Then** the status clearly indicates the current state:
- `choDuyet` displays as "Chờ duyệt" (Waiting for approval)
- `daDuyet` displays as "Đã duyệt" (Approved)
- `daVeTruong` displays as "Đã về trường" (Student returned)
- `tuChoi` displays as "Từ chối" (Rejected)

#### Scenario: Duty teacher can approve any pending leave request
**Given** a teacher logged in with duty teacher assignment
**When** they open the "Duyệt Về Phép" screen
**Then** the system SHALL show all requests with status `choDuyet` from all classes
**And** they can approve or reject any of these requests
**And** the system records their ID and name as the approver

#### Scenario: Homeroom teacher can approve leave requests from their class
**Given** a teacher logged in as homeroom teacher for a specific class
**When** they open the "Duyệt Về Phép" screen
**Then** the system SHALL show only requests with status `choDuyet` from their assigned class
**And** the system filters by their homeroom class ID (`id_lop`)
**And** they can approve or reject requests from their class only
**And** the system records their ID and name as the approver

#### Scenario: Teacher who is both duty and homeroom sees all relevant requests
**Given** a teacher is assigned as both duty teacher AND homeroom teacher
**When** they open the "Duyệt Về Phép" screen
**Then** the system SHALL show:
- All pending requests if they have duty teacher assignment, OR
- Only their class requests if they only have homeroom assignment
**And** they can approve any request they have permission to view

#### Scenario: Student views approval status after teacher approval
**Given** a student submitted a leave permission request
**When** a teacher approves the request
**Then** the student SHALL see the status change to "Đã duyệt" (Approved) in their history
**And** the student SHALL see the approving teacher's name
**And** the student SHALL see the approval timestamp
**And** no further approval is needed

#### Scenario: Parent views approval status for their child's leave request
**Given** a parent submitted a leave permission request for their child
**When** a teacher approves the request
**Then** the parent SHALL see the status change to "Đã duyệt" (Approved)
**And** the parent SHALL see which teacher approved the request
**And** the parent SHALL see when the approval was made

#### Scenario: Only one approval is required for leave permission
**Given** a leave permission request is submitted
**When** ANY authorized teacher (duty or homeroom) approves it
**Then** the request is fully approved with status `daDuyet`
**And** no additional approval is required
**And** the student can proceed with their leave immediately

#### Scenario: Rejected leave request shows rejecting teacher
**Given** a teacher rejected a leave permission request
**When** viewing the rejected request details
**Then** the system SHALL display the rejecting teacher's name
**And** the system SHALL display the rejection reason
**And** the rejection timestamp is shown
**And** the status shows "Từ chối" (Rejected)
