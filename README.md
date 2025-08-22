# Youth Activity and Lesson Coordination System

A comprehensive Clarity smart contract system for managing youth activities, lessons, and coordination between instructors, students, and parents.

## System Overview

This system provides a decentralized platform for managing youth activity programs with the following core features:

### Core Functionality

- **User Management**: Registration and role-based access for students, instructors, and parents
- **Class Scheduling**: Dynamic scheduling system with instructor availability tracking
- **Skill Progression**: Achievement milestones and progress tracking for students
- **Payment & Rentals**: Transparent pricing and equipment rental coordination
- **Communication**: Parent-instructor communication channels
- **Event Management**: Recital planning and performance opportunity coordination

### Smart Contract Architecture

The system consists of five interconnected Clarity contracts:

1. **user-management.clar** - Handles user registration, roles, and profiles
2. **class-scheduling.clar** - Manages class schedules and instructor availability
3. **skill-tracking.clar** - Tracks student progress and achievements
4. **payment-rental.clar** - Handles payments, pricing, and equipment rentals
5. **event-coordination.clar** - Manages events, recitals, and communications

## Technical Requirements

- **Blockchain**: Stacks blockchain using Clarity smart contracts
- **Testing**: Vitest test suite
- **Configuration**: Clarinet development environment
- **Syntax**: Pure Clarity syntax (no HTML entities)

## Contract Interactions

```clarity
;; Example: Enrolling a student in a class
(contract-call? .class-scheduling enroll-student class-id student-principal)

;; Example: Recording skill achievement
(contract-call? .skill-tracking record-achievement student-principal skill-id)

;; Example: Processing payment
(contract-call? .payment-rental process-payment student-principal amount)
