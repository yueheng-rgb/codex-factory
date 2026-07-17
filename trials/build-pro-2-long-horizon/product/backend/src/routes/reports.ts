import { Router, Request, Response } from 'express';
import { authenticate, authorize } from '../middleware/auth';
import * as svc from '../services/reports';
const router = Router();
router.use(authenticate);
router.get('/tickets', (req, res) => { res.json({ success: true, data: svc.getTicketMetrics(req.user.organizationId) }); });
router.get('/tasks', (req, res) => { res.json({ success: true, data: svc.getTaskMetrics(req.user.organizationId) }); });
router.get('/audit', authorize('admin'), (req, res) => { res.json({ success: true, data: svc.getAuditLog(req.user.organizationId) }); });
export default router;
