import { Router, Request, Response } from 'express';
import { authenticate, authorize, auditLog } from '../middleware/auth';
import * as svc from '../services/projects';
const router = Router();
router.use(authenticate);
router.get('/', (req, res) => { res.json({ success: true, data: svc.listProjects(req.user.organizationId) }); });
router.post('/', authorize('admin','manager'), (req, res) => {
  const project = svc.createProject({ ...req.body, organizationId: req.user.organizationId, leadId: req.user.userId });
  auditLog(req, 'CREATE', 'project', project.id);
  res.json({ success: true, data: project });
});
router.put('/:id', authorize('admin','manager'), (req, res) => {
  const project = svc.updateProject(req.params.id, req.body);
  auditLog(req, 'UPDATE', 'project', req.params.id);
  res.json({ success: true, data: project });
});
export default router;
