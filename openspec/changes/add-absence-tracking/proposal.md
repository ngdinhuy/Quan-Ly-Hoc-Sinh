# Proposal: Add Absence Tracking

## Summary

Extend the attendance tracking system to track students who haven't checked in (absent without leave), display absence statistics in admin dashboard, and show absence history to parents.

## Background

Currently, the attendance system tracks:
- On-time check-ins (`dungGio`)
- Late check-ins (`tre`)
- Excused absences from leave permissions (`vangPhep`)

However, students who don't check in at all are not explicitly tracked. This proposal adds:
1. Automatic absence detection after attendance period ends
2. Absence statistics in admin dashboard
3. Absence history view for parents

## Scope

### In Scope
- Add absence count to admin late statistics screen (rename to "Thống Kê Điểm Danh")
- Add absence column to statistics table
- Show absent students in detail dialog
- Create parent absence history screen
- Add absence card to parent main screen

### Out of Scope
- Automatic notifications for absences
- Batch absence record creation (absences calculated on-demand)
- Teacher absence management screen

## Design Decisions

### On-Demand Calculation vs Stored Records
**Decision**: Calculate absences on-demand rather than creating absence records in database.

**Rationale**:
- Simpler implementation - no background jobs needed
- No storage overhead for absence records
- Absence = students in class - students who checked in - students on leave
- Can be calculated at any time for any period

### Absence Definition
A student is considered absent for a period when:
1. The period has ended (current time > period end time + buffer)
2. Student has no check-in record for that period
3. Student does not have approved leave for that date

## User Stories

1. **Admin views absence statistics**: Admin opens statistics screen and sees absence counts alongside late counts per class
2. **Admin views absent students**: Admin clicks detail button and sees list of absent students (no check-in)
3. **Parent views child's absences**: Parent opens absence history and sees dates/periods where child was absent

## Technical Approach

1. Add `getAbsentStudents(idLop, date, ca)` method to DiemDanhService
2. Extend `_ClassLateStats` to include `absentCount` and `absentStudents`
3. Update admin statistics UI with absence column
4. Create parent absence history screen similar to late history
