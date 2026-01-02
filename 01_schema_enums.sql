-- Part 1: Schema and Enums

-- Enable pgcrypto (standard way)
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Create Schema
CREATE SCHEMA IF NOT EXISTS hrmswishluv;

-- Enums
CREATE TYPE hrmswishluv.user_role AS ENUM ('admin', 'manager', 'employee');
CREATE TYPE hrmswishluv.leave_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE hrmswishluv.leave_type AS ENUM ('sick', 'vacation', 'personal', 'maternity', 'paternity');
CREATE TYPE hrmswishluv.expense_status AS ENUM ('submitted', 'approved', 'rejected', 'reimbursed');
CREATE TYPE hrmswishluv.attendance_status AS ENUM ('present', 'absent', 'late', 'half_day');
