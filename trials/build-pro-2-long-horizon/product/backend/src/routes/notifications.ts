import { Router, Request, Response } from 'express';
import { authenticate } from '../middleware/auth';
import * as svc from '../services/notifications';
const router = Router();
router.use(authenticate);
router.get('/', (req, res) => { res.json({ success: true, data: svc.listNotifications(req.user.userId) }); });
router.get('/unread-count', (req, res) => { res.json({ success: true, data: svc.unreadCount(req.user.userId) }); });
router.put('/:id/read', (req, res) => { svc.markRead(req.params.id); res.json({ success: true }); });
export default router;
