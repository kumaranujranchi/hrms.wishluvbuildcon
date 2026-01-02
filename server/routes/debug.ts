import { Router } from 'express';
import { db } from '../db';
import { users, attendance } from '@shared/schema';
import { sql } from 'drizzle-orm';
import bcrypt from 'bcryptjs';

const router = Router();

// Debug endpoint to check database connection and data
router.get('/api/debug/db-info', async (req, res) => {
  try {
    // Get user count
    const userCountResult = await db
      .select({ count: sql<number>`count(*)` })
      .from(users);
    
    const userCount = Number(userCountResult[0]?.count || 0);
    
    // Get recent users
    const recentUsers = await db
      .select({
        email: users.email,
        firstName: users.firstName,
        role: users.role,
        createdAt: users.createdAt
      })
      .from(users)
      .orderBy(sql`${users.createdAt} DESC`)
      .limit(5);
    
    res.json({
      status: 'connected',
      userCount,
      recentUsers,
      environment: process.env.NODE_ENV,
      databaseUrl: process.env.DATABASE_URL ? 'Present' : 'Missing'
    });
  } catch (error) {
    res.status(500).json({ 
      error: 'Database connection failed', 
      details: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

// Debug endpoint to sync production data to development
router.post('/api/debug/sync-production-data', async (req, res) => {
   res.status(501).json({ message: 'Not implemented' });
});

// Debug endpoint to create sample attendance data
router.post('/api/debug/create-sample-attendance', async (req, res) => {
    res.status(501).json({ message: 'Not implemented' });
});

// Production data validation endpoint
router.get('/api/debug/validate-production-sync', async (req, res) => {
    try {
        const userCountResult = await db
          .select({ count: sql<number>`count(*)` })
          .from(users);
        
        const attendanceCountResult = await db
          .select({ count: sql<number>`count(*)` })
          .from(attendance);
        
        res.json({
            status: 'success',
            dataSync: {
                totalUsers: Number(userCountResult[0]?.count || 0),
                totalAttendance: Number(attendanceCountResult[0]?.count || 0)
            }
        });
    } catch (error) {
        res.status(500).json({ error: 'Validation failed' });
    }
});

export default router;