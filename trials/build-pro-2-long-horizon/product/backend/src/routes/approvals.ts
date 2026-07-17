import { Router, Request, Response } from 'express';
import { authenticate, authorize, auditLog } from '../middleware/auth';
import * as svc from '../services/approvals';
const router = Router();
router.use(authenticate);
router.post('/', (req, res) => {
  const approval = svc.createApproval({ ...req.body, requestedById: req.user.userId }) as any;
  auditLog(req, 'CREATE', 'approval', approval.id);
  res.json({ success: true, data: approval });
});
router.put('/:id', authorize('admin','manager'), (req, res) => {
  const approval = svc.updateApproval(req.params.id, { ...req.body, approvedById: req.user.userId }) as any;
  auditLog(req, 'UPDATE', 'approval', req.params.id);
  res.json({ success: true, data: approval });
});
router.get('/ticket/:ticketId', (req, res) => { res.json({ success: true, data: svc.listApprovals(req.params.ticketId) }); });
export default router;
