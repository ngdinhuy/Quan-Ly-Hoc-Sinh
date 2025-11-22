# Meal Deduction Tracking for Leave Permission System

## ADDED Requirements

### Requirement: Track specific meal deduction dates in new leave permission system
When a student is granted formal leave permission (xin về phép) through the new system, the system SHALL track a list of specific dates for meal deduction to provide flexibility and accuracy in meal planning and cost management.

**Note:** This is for the new `xin_ve_phep` system only, not the existing `xin_ra_vao` system.

**Related to**: `guardian-pickup-info`

#### Scenario: System generates list of available dates for meal deduction
**Given** a leave permission request specifies leave start date (`ngayXinVe`) and expected return date (`ngayXuongTruong`)
**When** both dates are entered in the form
**Then** the system automatically generates a list of all dates between start and return date (inclusive)
**And** displays these dates as selectable options for meal deduction
**And** by default, all dates are selected (full meal deduction)

#### Scenario: User selects specific dates for meal deduction
**Given** the system has generated a list of available dates for the leave period
**When** the student, parent, or teacher fills out the request form
**Then** they can select/deselect individual dates for meal deduction
**And** the UI provides checkboxes or calendar interface for date selection
**And** selected dates are stored in the `danh_sach_ngay_cat_com` array
**And** each date is stored as a timestamp (date only, no time component)

#### Scenario: Partial meal deduction selection
**Given** a student is on leave for 5 days
**When** the student plans to return to school for lunch on day 2 and day 4
**Then** they can deselect day 2 and day 4 from the meal deduction list
**And** only 3 dates remain selected for meal deduction
**And** these 3 specific dates are stored in `danh_sach_ngay_cat_com`

#### Scenario: Display meal deduction dates in leave permission details
**Given** a leave permission includes specific meal deduction dates
**When** viewing the request details (by student, parent, or teacher)
**Then** the list of meal deduction dates is clearly displayed
**And** shows count: "Cắt cơm [X] ngày" where X = length of `danh_sach_ngay_cat_com`
**And** shows detailed list of dates in dd/MM/yyyy format
**And** stored in the `danh_sach_ngay_cat_com` array field in Firestore

#### Scenario: Empty meal deduction list is allowed
**Given** a student requests leave permission
**When** they deselect all meal deduction dates (e.g., will eat at home)
**Then** the system accepts an empty `danh_sach_ngay_cat_com` array
**And** displays "Không cắt cơm" (No meal deduction)
**And** the request can still be submitted successfully

#### Scenario: Meal deduction dates must be within leave period
**Given** a student is selecting meal deduction dates
**When** they attempt to select a date outside the leave period
**Then** the system SHALL NOT allow selection of dates before `ngayXinVe`
**And** SHALL NOT allow selection of dates after `ngayXuongTruong`
**And** only dates within the leave period are selectable

#### Scenario: Meal deduction updates when leave dates change
**Given** a student has selected meal deduction dates
**When** they change the leave start date or return date
**Then** the system regenerates the list of available dates
**And** previously selected dates that are still within the new range remain selected
**And** previously selected dates outside the new range are removed from selection

#### Scenario: Same-day leave has no meal deduction options
**Given** a student requests leave for a few hours on the same day
**When** the return date is the same as the leave date
**Then** the meal deduction list is empty (no dates to select)
**And** `danh_sach_ngay_cat_com` is an empty array
**And** displays "Không cắt cơm" since it's same-day leave

#### Scenario: Multi-day leave with flexible meal deduction
**Given** a student requests leave from Monday to Friday (5 days)
**When** filling out the form
**Then** the system shows 5 selectable dates (Mon, Tue, Wed, Thu, Fri)
**And** student can choose any combination (e.g., only Mon, Wed, Fri for 3 days)
**And** provides flexibility for partial meal deduction based on actual needs
