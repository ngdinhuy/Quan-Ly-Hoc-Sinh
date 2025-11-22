# Add Student Leave Permission System (Xin Về Phép)

## Overview
Create a new, separate student leave permission system (`XinVePhep`) distinct from the existing temporary exit system (`XinRaVao`). The new system captures guardian pickup information, tracks meal deductions, and implements a two-level approval workflow (duty teacher + homeroom teacher).

## Problem Statement
The current system only supports temporary exits (`xin ra ngoài`) for short-term absences. Schools need a separate, more comprehensive leave permission system (`xin về phép`) for longer absences that includes:
- Verification of who picks up the student (name, ID, contact)
- Automatic meal deduction tracking when students are on extended leave
- Two-level approval for better accountability and oversight
- Clear separation between temporary exits and formal leave permissions

## Proposed Solution
Create a new `XinVePhep` model and related infrastructure to handle formal leave permissions:
1. **New Firestore collection**: `xin_ve_phep` (separate from `xin_ra_vao`)
2. **Guardian pickup details**: Name, CCCD (Citizen ID), phone number
3. **Meal deduction**: Number of days to deduct meals
4. **Two-level approval**: Duty teacher (giáo viên trực ban) and homeroom teacher (giáo viên chủ nhiệm)
5. **New screens**: Dedicated UI for creating and managing leave permissions

## Scope
- **In Scope**:
  - Create new `XinVePhep` model with all required fields
  - Create new `XinVePhepService` for Firebase operations
  - Create new screens for students/parents to request leave permissions
  - Create new teacher screens to review and approve leave permissions
  - Implement two-level approval workflow (duty teacher → homeroom teacher)
  - Add guardian info and meal deduction validation
  - Keep existing `XinRaVao` system completely unchanged

- **Out of Scope**:
  - Modifying existing `xin_ra_vao` table or screens
  - Actual meal system integration (just tracking the number)
  - Notification system for approval workflow
  - Guardian identity verification via external systems
  - Merging or migrating data between the two systems

## Dependencies
- Firebase Firestore for data persistence
- Existing authentication and role management
- Existing teacher and student models
- Existing patterns from `XinRaVao` as reference (but separate implementation)

## Success Criteria
- New `xin_ve_phep` collection in Firestore with complete schema
- Students/parents can submit leave permission requests with all guardian info
- Meal deduction days are calculated and displayed
- Both duty teacher and homeroom teacher must approve before final approval
- Existing `xin_ra_vao` functionality remains completely unchanged
- New screens are accessible from appropriate user role menus

## Timeline Estimate
- Medium change, approximately 8-10 hours of development time (more complex due to separate implementation)
