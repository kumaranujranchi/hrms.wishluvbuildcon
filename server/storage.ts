import {
  type User,
  type InsertUser,
  type Attendance,
  type InsertAttendance,
  type LeaveRequest,
  type InsertLeaveRequest,
  type ExpenseClaim,
  type InsertExpenseClaim,
  type Payroll,
  type InsertPayroll,
  type Announcement,
  type InsertAnnouncement,
  type CompanySettings,
  type EmployeeProfile,
  type InsertEmployeeProfile,
  type Department,
  type InsertDepartment,
  type Designation,
  type InsertDesignation,
  type LeaveAssignment,
  type InsertLeaveAssignment,
  type EmployeeSalaryStructure,
  type InsertEmployeeSalaryStructure,
  users,
  attendance,
  leaveRequests,
  expenseClaims,
  payroll,
  announcements,
  companySettings,
  employeeProfiles,
  departments,
  designations,
  leaveAssignments,
  employeeSalaryStructure,
} from "@shared/schema";
import { db } from "./db";
import { eq, and, gte, lte, desc, sql } from "drizzle-orm";

export interface IStorage {
  // User operations 
  getUser(id: string): Promise<User | undefined>;
  getUserByEmail(email: string): Promise<User | undefined>;
  changeUserPassword(userId: string, currentPassword: string, newPassword: string): Promise<boolean>;
  createUser(userData: { email: string; passwordHash: string; firstName: string; lastName: string; }): Promise<User>;
  createEmployeeByAdmin(userData: { email: string; passwordHash: string; firstName: string; lastName: string; department?: string; position?: string; needsPasswordReset?: boolean; }): Promise<User>;
  updateUser(id: string, updates: Partial<User>): Promise<User>;
  upsertUser(id: string, userData: { email: string; firstName: string; lastName: string; profileImageUrl?: string; role?: string; }): Promise<User>;
  
  // Employee operations
  getAllEmployees(): Promise<User[]>;
  getEmployeesByManager(managerId: string): Promise<User[]>;
  updateEmployee(id: string, updates: Partial<User>): Promise<User>;
  deleteEmployee(id: string): Promise<void>;
  
  // Attendance operations
  markAttendance(attendance: InsertAttendance): Promise<Attendance>;
  updateAttendance(id: string, updates: Partial<Attendance>): Promise<Attendance>;
  getAttendanceByUser(userId: string, startDate?: Date, endDate?: Date): Promise<Attendance[]>;
  getTodayAttendance(userId: string): Promise<Attendance | undefined>;
  getAttendanceStats(startDate?: Date, endDate?: Date): Promise<any>;
  
  // Admin attendance operations
  getTodayAttendanceForAll(): Promise<any[]>;
  getAttendanceRangeForAll(startDate: string, endDate: string): Promise<any[]>;
  
  // Admin payroll operations
  createPayrollRecord(payrollData: InsertPayroll): Promise<Payroll>;
  getPayrollRecords(month?: number, year?: number): Promise<any[]>;
  processPayrollRecord(recordId: string): Promise<Payroll>;
  getPayrollRecordById(recordId: string): Promise<Payroll | undefined>;
  
  // Employee salary structure operations
  createOrUpdateSalaryStructure(structureData: InsertEmployeeSalaryStructure): Promise<EmployeeSalaryStructure>;
  getEmployeeSalaryStructure(userId: string): Promise<EmployeeSalaryStructure | undefined>;
  getAllEmployeesWithSalaryStructure(): Promise<any[]>;
  
  // Admin leave management operations
  createLeaveAssignment(assignmentData: InsertLeaveAssignment): Promise<LeaveAssignment>;
  getLeaveAssignments(): Promise<any[]>;
  getAllLeaveRequests(): Promise<any[]>;
  respondToLeaveRequest(requestId: string, status: string, notes?: string, approverId?: string): Promise<LeaveRequest>;
  updateLeaveBalance(userId: string, leaveType: string, days: number): Promise<void>;
  
  // Leave operations
  createLeaveRequest(leaveRequest: InsertLeaveRequest): Promise<LeaveRequest>;
  getLeaveRequestsByUser(userId: string): Promise<LeaveRequest[]>;
  getPendingLeaveRequests(approverId?: string): Promise<LeaveRequest[]>;
  updateLeaveRequestStatus(id: string, status: string, approverId: string, notes?: string): Promise<LeaveRequest>;
  
  // Expense operations
  createExpenseClaim(expense: InsertExpenseClaim): Promise<ExpenseClaim>;
  getExpenseClaimsByUser(userId: string): Promise<ExpenseClaim[]>;
  getPendingExpenseClaims(approverId?: string): Promise<ExpenseClaim[]>;
  updateExpenseClaimStatus(id: string, status: string, approverId: string, notes?: string): Promise<ExpenseClaim>;
  
  // Payroll operations
  getPayrollByUser(userId: string): Promise<Payroll[]>;
  getPayrollByUserAndPeriod(userId: string, month: number, year: number): Promise<Payroll | undefined>;
  
  // Employee Profile operations
  getEmployeeProfile(userId: string): Promise<EmployeeProfile | undefined>;
  createEmployeeProfile(profile: InsertEmployeeProfile): Promise<EmployeeProfile>;
  updateEmployeeProfile(userId: string, updates: Partial<EmployeeProfile>): Promise<EmployeeProfile>;
  
  // Announcements operations
  createAnnouncement(announcement: InsertAnnouncement): Promise<Announcement>;
  getActiveAnnouncements(): Promise<Announcement[]>;
  
  // Company settings
  getCompanySettings(): Promise<CompanySettings | undefined>;
  updateCompanySettings(settings: Partial<CompanySettings>): Promise<CompanySettings>;

  // Department operations
  getDepartments(): Promise<Department[]>;
  createDepartment(department: InsertDepartment & { createdBy: string }): Promise<Department>;
  updateDepartment(id: string, department: InsertDepartment): Promise<Department | null>;
  deleteDepartment(id: string): Promise<boolean>;

  // Designation operations
  getDesignations(): Promise<(Designation & { department?: Department })[]>;
  createDesignation(designation: InsertDesignation & { createdBy: string }): Promise<Designation>;
  updateDesignation(id: string, designation: InsertDesignation): Promise<Designation | null>;
  deleteDesignation(id: string): Promise<boolean>;
}

export class DatabaseStorage implements IStorage {
  // User operations
  async getUser(id: string): Promise<User | undefined> {
    const result = await db
      .select()
      .from(users)
      .where(eq(users.id, id))
      .limit(1);
    
    return result[0];
  }

  async getUserByEmail(email: string): Promise<User | undefined> {
    const result = await db
      .select()
      .from(users)
      .where(eq(users.email, email))
      .limit(1);
    
    return result[0];
  }

  async changeUserPassword(userId: string, currentPassword: string, newPassword: string): Promise<boolean> {
    try {
      const user = await this.getUser(userId);
      if (!user) return false;

      const bcrypt = await import('bcryptjs');
      const isCurrentPasswordValid = await bcrypt.compare(currentPassword, user.passwordHash);
      if (!isCurrentPasswordValid) return false;

      const newPasswordHash = await bcrypt.hash(newPassword, 10);

      await db
        .update(users)
        .set({ 
          passwordHash: newPasswordHash,
          updatedAt: new Date()
        })
        .where(eq(users.id, userId));

      return true;
    } catch (error) {
      console.error("Error changing password:", error);
      return false;
    }
  }

  async createUser(userData: { email: string; passwordHash: string; firstName: string; lastName: string; }): Promise<User> {
    const result = await db
      .insert(users)
      .values({
        email: userData.email,
        passwordHash: userData.passwordHash,
        firstName: userData.firstName,
        lastName: userData.lastName,
        role: 'employee',
        isOnboardingComplete: false,
        needsPasswordReset: true
      })
      .returning();

    return result[0];
  }

  async createEmployeeByAdmin(userData: { email: string; passwordHash: string; firstName: string; lastName: string; department?: string; position?: string; needsPasswordReset?: boolean; }): Promise<User> {
    const result = await db
      .insert(users)
      .values({
        email: userData.email,
        passwordHash: userData.passwordHash,
        firstName: userData.firstName,
        lastName: userData.lastName,
        department: userData.department,
        position: userData.position,
        role: 'employee',
        needsPasswordReset: userData.needsPasswordReset ?? true,
      })
      .returning();

    return result[0];
  }

  async updateUser(id: string, updates: Partial<User>): Promise<User> {
    const result = await db
      .update(users)
      .set({ ...updates, updatedAt: new Date() })
      .where(eq(users.id, id))
      .returning();

    if (!result[0]) throw new Error("User not found");
    return result[0];
  }

  async upsertUser(id: string, userData: { email: string; firstName: string; lastName: string; profileImageUrl?: string; role?: string; }): Promise<User> {
    const existingUser = await this.getUser(id);
    
    if (existingUser) {
      return this.updateUser(id, userData);
    } else {
      const result = await db
        .insert(users)
        .values({
          id,
          email: userData.email,
          firstName: userData.firstName,
          lastName: userData.lastName,
          profileImageUrl: userData.profileImageUrl,
          passwordHash: 'oauth-placeholder',
          needsPasswordReset: false,
          role: (userData.role as 'admin' | 'manager' | 'employee') || 'employee'
        })
        .returning();
        
      return result[0];
    }
  }

  // Employee operations
  async getAllEmployees(): Promise<User[]> {
    return await db
      .select()
      .from(users)
      .where(eq(users.isActive, true));
  }

  async getEmployeesByManager(managerId: string): Promise<User[]> {
    return await db
      .select()
      .from(users)
      .where(
        and(
          eq(users.managerId, managerId),
          eq(users.isActive, true)
        )
      );
  }

  async updateEmployee(id: string, updates: Partial<User>): Promise<User> {
    return this.updateUser(id, updates);
  }

  async deleteEmployee(id: string): Promise<void> {
    // Delete related records first
    await db.delete(attendance).where(eq(attendance.userId, id));
    await db.delete(leaveRequests).where(eq(leaveRequests.userId, id));
    await db.delete(expenseClaims).where(eq(expenseClaims.userId, id));
    await db.delete(payroll).where(eq(payroll.userId, id));
    await db.delete(employeeProfiles).where(eq(employeeProfiles.userId, id));
    await db.delete(leaveAssignments).where(eq(leaveAssignments.userId, id));
    await db.delete(employeeSalaryStructure).where(eq(employeeSalaryStructure.userId, id));
    
    await db.delete(users).where(eq(users.id, id));
  }

  // Attendance operations
  async markAttendance(attendanceData: InsertAttendance): Promise<Attendance> {
    const result = await db
      .insert(attendance)
      .values(attendanceData)
      .returning();

    return result[0];
  }

  async updateAttendance(id: string, updates: Partial<Attendance>): Promise<Attendance> {
    const result = await db
      .update(attendance)
      .set(updates)
      .where(eq(attendance.id, id))
      .returning();

    if (!result[0]) throw new Error("Attendance record not found");
    return result[0];
  }

  async getAttendanceByUser(userId: string, startDate?: Date, endDate?: Date): Promise<Attendance[]> {
    let conditions = [eq(attendance.userId, userId)];
    
    if (startDate) conditions.push(gte(attendance.date, startDate));
    if (endDate) conditions.push(lte(attendance.date, endDate));

    return await db
      .select()
      .from(attendance)
      .where(and(...conditions))
      .orderBy(desc(attendance.date));
  }

  async getTodayAttendance(userId: string): Promise<Attendance | undefined> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const result = await db
      .select()
      .from(attendance)
      .where(
        and(
          eq(attendance.userId, userId),
          gte(attendance.date, today),
          lte(attendance.date, tomorrow)
        )
      )
      .limit(1);

    return result[0];
  }

  async getAttendanceStats(startDate?: Date, endDate?: Date): Promise<any> {
    // Simplified stats - can be enhanced with more complex queries
    return {
      totalEmployees: 0,
      presentToday: 0,
      lateToday: 0,
      absentToday: 0,
      averageWorkingHours: 0,
      attendanceRate: 0,
    };
  }
  
  async getTodayAttendanceForAll(): Promise<any[]> {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    return await db
      .select()
      .from(attendance)
      .where(
        and(
          gte(attendance.date, today),
          lte(attendance.date, tomorrow)
        )
      );
  }

  async getAttendanceRangeForAll(startDate: string, endDate: string): Promise<any[]> {
    return await db
      .select()
      .from(attendance)
      .where(
        and(
          gte(attendance.date, new Date(startDate)),
          lte(attendance.date, new Date(endDate))
        )
      );
  }

  // Leave operations
  async createLeaveRequest(leaveRequestData: InsertLeaveRequest): Promise<LeaveRequest> {
    const result = await db
      .insert(leaveRequests)
      .values(leaveRequestData)
      .returning();

    return result[0];
  }

  async getLeaveRequestsByUser(userId: string): Promise<LeaveRequest[]> {
    return await db
      .select()
      .from(leaveRequests)
      .where(eq(leaveRequests.userId, userId))
      .orderBy(desc(leaveRequests.createdAt));
  }

  async getPendingLeaveRequests(approverId?: string): Promise<LeaveRequest[]> {
    return await db
      .select()
      .from(leaveRequests)
      .where(eq(leaveRequests.status, 'pending'))
      .orderBy(desc(leaveRequests.createdAt));
  }

  async updateLeaveRequestStatus(id: string, status: string, approverId: string, notes?: string): Promise<LeaveRequest> {
    const result = await db
      .update(leaveRequests)
      .set({
        status: status as any,
        approverId,
        approverNotes: notes,
        updatedAt: new Date()
      })
      .where(eq(leaveRequests.id, id))
      .returning();

    if (!result[0]) throw new Error("Leave request not found");
    return result[0];
  }

  async getAllLeaveRequests(): Promise<any[]> {
    return await db
      .select()
      .from(leaveRequests)
      .orderBy(desc(leaveRequests.createdAt));
  }

  async respondToLeaveRequest(requestId: string, status: string, notes?: string, approverId?: string): Promise<LeaveRequest> {
    return this.updateLeaveRequestStatus(requestId, status, approverId || '', notes);
  }

  async updateLeaveBalance(userId: string, leaveType: string, days: number): Promise<void> {
    // Implementation for updating leave balance
    // This would update the leaveAssignments table
  }

  // Expense operations
  async createExpenseClaim(expenseData: InsertExpenseClaim): Promise<ExpenseClaim> {
    const result = await db
      .insert(expenseClaims)
      .values(expenseData)
      .returning();

    return result[0];
  }

  async getExpenseClaimsByUser(userId: string): Promise<ExpenseClaim[]> {
    return await db
      .select()
      .from(expenseClaims)
      .where(eq(expenseClaims.userId, userId))
      .orderBy(desc(expenseClaims.submissionDate));
  }

  async getPendingExpenseClaims(approverId?: string): Promise<ExpenseClaim[]> {
    return await db
      .select()
      .from(expenseClaims)
      .where(eq(expenseClaims.status, 'submitted'))
      .orderBy(desc(expenseClaims.submissionDate));
  }

  async updateExpenseClaimStatus(id: string, status: string, approverId: string, notes?: string): Promise<ExpenseClaim> {
    const updateData: any = {
      status: status as any,
      approverId,
      approverNotes: notes,
    };
    
    if (status === 'approved') {
      updateData.approvalDate = new Date();
    }

    const result = await db
      .update(expenseClaims)
      .set(updateData)
      .where(eq(expenseClaims.id, id))
      .returning();

    if (!result[0]) throw new Error("Expense claim not found");
    return result[0];
  }

  // Payroll operations
  async getPayrollByUser(userId: string): Promise<Payroll[]> {
    return await db
      .select()
      .from(payroll)
      .where(eq(payroll.userId, userId))
      .orderBy(desc(payroll.year), desc(payroll.month));
  }

  async getPayrollByUserAndPeriod(userId: string, month: number, year: number): Promise<Payroll | undefined> {
    const result = await db
      .select()
      .from(payroll)
      .where(
        and(
          eq(payroll.userId, userId),
          eq(payroll.month, month),
          eq(payroll.year, year)
        )
      )
      .limit(1);

    return result[0];
  }

  async createPayrollRecord(payrollData: InsertPayroll): Promise<Payroll> {
    const result = await db
      .insert(payroll)
      .values(payrollData)
      .returning();

    return result[0];
  }

  async getPayrollRecords(month?: number, year?: number): Promise<any[]> {
    let conditions = [];
    
    if (month) conditions.push(eq(payroll.month, month));
    if (year) conditions.push(eq(payroll.year, year));

    if (conditions.length > 0) {
      return await db
        .select()
        .from(payroll)
        .where(and(...conditions));
    }

    return await db.select().from(payroll);
  }

  async processPayrollRecord(recordId: string): Promise<Payroll> {
    const result = await db
      .update(payroll)
      .set({
        status: 'processed',
        processedAt: new Date()
      })
      .where(eq(payroll.id, recordId))
      .returning();

    if (!result[0]) throw new Error("Payroll record not found");
    return result[0];
  }

  async getPayrollRecordById(recordId: string): Promise<Payroll | undefined> {
    const result = await db
      .select()
      .from(payroll)
      .where(eq(payroll.id, recordId))
      .limit(1);

    return result[0];
  }

  // Salary Structure
  async createOrUpdateSalaryStructure(structureData: InsertEmployeeSalaryStructure): Promise<EmployeeSalaryStructure> {
    const existing = await this.getEmployeeSalaryStructure(structureData.userId);
    
    if (existing) {
      const result = await db
        .update(employeeSalaryStructure)
        .set({ ...structureData, updatedAt: new Date() })
        .where(eq(employeeSalaryStructure.userId, structureData.userId))
        .returning();

      return result[0];
    } else {
      const result = await db
        .insert(employeeSalaryStructure)
        .values(structureData)
        .returning();

      return result[0];
    }
  }

  async getEmployeeSalaryStructure(userId: string): Promise<EmployeeSalaryStructure | undefined> {
    const result = await db
      .select()
      .from(employeeSalaryStructure)
      .where(eq(employeeSalaryStructure.userId, userId))
      .limit(1);

    return result[0];
  }

  async getAllEmployeesWithSalaryStructure(): Promise<any[]> {
    return await db
      .select()
      .from(employeeSalaryStructure);
  }

  // Leave Assignment
  async createLeaveAssignment(assignmentData: InsertLeaveAssignment): Promise<LeaveAssignment> {
    const result = await db
      .insert(leaveAssignments)
      .values(assignmentData)
      .returning();

    return result[0];
  }

  async getLeaveAssignments(): Promise<any[]> {
    return await db
      .select()
      .from(leaveAssignments);
  }

  // Employee Profile
  async getEmployeeProfile(userId: string): Promise<EmployeeProfile | undefined> {
    const result = await db
      .select()
      .from(employeeProfiles)
      .where(eq(employeeProfiles.userId, userId))
      .limit(1);

    return result[0];
  }

  async createEmployeeProfile(profile: InsertEmployeeProfile): Promise<EmployeeProfile> {
    const result = await db
      .insert(employeeProfiles)
      .values(profile)
      .returning();

    return result[0];
  }

  async updateEmployeeProfile(userId: string, updates: Partial<EmployeeProfile>): Promise<EmployeeProfile> {
    const result = await db
      .update(employeeProfiles)
      .set({ ...updates, updatedAt: new Date() })
      .where(eq(employeeProfiles.userId, userId))
      .returning();

    if (!result[0]) throw new Error("Employee profile not found");
    return result[0];
  }

  // Announcements
  async createAnnouncement(announcementData: InsertAnnouncement): Promise<Announcement> {
    const result = await db
      .insert(announcements)
      .values(announcementData)
      .returning();

    return result[0];
  }

  async getActiveAnnouncements(): Promise<Announcement[]> {
    return await db
      .select()
      .from(announcements)
      .where(eq(announcements.isActive, true))
      .orderBy(desc(announcements.createdAt))
      .limit(5);
  }

  // Company Settings
  async getCompanySettings(): Promise<CompanySettings | undefined> {
    const result = await db
      .select()
      .from(companySettings)
      .limit(1);

    return result[0];
  }

  async updateCompanySettings(settings: Partial<CompanySettings>): Promise<CompanySettings> {
    const existing = await this.getCompanySettings();
    
    if (existing) {
      const result = await db
        .update(companySettings)
        .set({ ...settings, updatedAt: new Date() })
        .where(eq(companySettings.id, existing.id))
        .returning();

      return result[0];
    } else {
      const result = await db
        .insert(companySettings)
        .values(settings as any)
        .returning();

      return result[0];
    }
  }

  // Departments
  async getDepartments(): Promise<Department[]> {
    return await db
      .select()
      .from(departments)
      .orderBy(desc(departments.createdAt));
  }

  async createDepartment(department: InsertDepartment & { createdBy: string }): Promise<Department> {
    const result = await db
      .insert(departments)
      .values(department)
      .returning();

    return result[0];
  }

  async updateDepartment(id: string, department: InsertDepartment): Promise<Department | null> {
    const result = await db
      .update(departments)
      .set({ ...department, updatedAt: new Date() })
      .where(eq(departments.id, id))
      .returning();

    return result[0] || null;
  }

  async deleteDepartment(id: string): Promise<boolean> {
    await db.delete(departments).where(eq(departments.id, id));
    return true;
  }

  // Designations
  async getDesignations(): Promise<(Designation & { department?: Department })[]> {
    return await db
      .select()
      .from(designations)
      .orderBy(desc(designations.createdAt)) as any;
  }

  async createDesignation(designation: InsertDesignation & { createdBy: string }): Promise<Designation> {
    const result = await db
      .insert(designations)
      .values(designation)
      .returning();

    return result[0];
  }

  async updateDesignation(id: string, designation: InsertDesignation): Promise<Designation | null> {
    const result = await db
      .update(designations)
      .set({ ...designation, updatedAt: new Date() })
      .where(eq(designations.id, id))
      .returning();

    return result[0] || null;
  }

  async deleteDesignation(id: string): Promise<boolean> {
    await db.delete(designations).where(eq(designations.id, id));
    return true;
  }
}

export const storage = new DatabaseStorage();
