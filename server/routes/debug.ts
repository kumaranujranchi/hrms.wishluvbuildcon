import { Router } from 'express';
import { supabase } from '../db';
import bcrypt from 'bcryptjs';

const router = Router();

// Debug endpoint to check database connection and data
router.get('/api/debug/db-info', async (req, res) => {
  try {
    // Get user count
    const { count, error } = await supabase
      .from('hrms_users')
      .select('*', { count: 'exact', head: true });
    
    if (error) throw error;
    
    // Get recent users
    const { data: recentUsers } = await supabase
      .from('hrms_users')
      .select('email, first_name, role, created_at')
      .order('created_at', { ascending: false })
      .limit(5);
    
    res.json({
      status: 'connected',
      userCount: count,
      recentUsers: recentUsers,
      environment: process.env.NODE_ENV,
      supabaseUrl: process.env.VITE_SUPABASE_URL ? 'Present' : 'Missing'
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
   res.status(501).json({ message: 'Not implemented for Supabase API mode' });
});

// Debug endpoint to create sample attendance data
router.post('/api/debug/create-sample-attendance', async (req, res) => {
    res.status(501).json({ message: 'Not implemented for Supabase API mode' });
});

// Production data validation endpoint
router.get('/api/debug/validate-production-sync', async (req, res) => {
    try {
        const { count: userCount } = await supabase.from('hrms_users').select('*', { count: 'exact', head: true });
        const { count: attendanceCount } = await supabase.from('hrms_attendance').select('*', { count: 'exact', head: true });
        
        res.json({
            status: 'success',
            dataSync: {
                totalUsers: userCount,
                totalAttendance: attendanceCount
            }
        });
    } catch (error) {
        res.status(500).json({ error: 'Validation failed' });
    }
});

export default router;