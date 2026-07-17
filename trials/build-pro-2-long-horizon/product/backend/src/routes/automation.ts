import { Router, Request, Response } from 'express';
import { authenticate, authorize, auditLog } from '../middleware/auth';
import * as svc from '../services/automation';
const router = Router();
router.use(authenticate);
router.get('/', (req, res) => { res.json({ success: true, data: svc.listRules(req.user.organizationId) }); });
router.post('/', authorize('admin','manager'), (req, res) => { const r = svc.createRule({...req.body,organizationId:req.user.organizationId}) as any; auditLog(req,'CREATE','automation_rule',r.id); res.json({success:true,data:r}); });
router.put('/:id', authorize('admin','manager'), (req, res) => { const r = svc.updateRule(req.params.id, req.body) as any; auditLog(req,'UPDATE','automation_rule',req.params.id); res.json({success:true,data:r}); });
export default router;
