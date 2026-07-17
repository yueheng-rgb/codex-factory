import { Router, Request, Response } from 'express';
import { authenticate, auditLog } from '../middleware/auth';
import * as svc from '../services/tasks';
const router = Router();
router.use(authenticate);
router.get('/project/:projectId', (req, res) => { res.json({ success: true, data: svc.listTasks(req.params.projectId) }); });
router.post('/', (req, res) => {
  const task = svc.createTask(req.body);
  auditLog(req, 'CREATE', 'task', task.id);
  res.json({ success: true, data: task });
});
router.put('/:id', (req, res) => {
  const task = svc.updateTask(req.params.id, req.body);
  auditLog(req, 'UPDATE', 'task', req.params.id);
  res.json({ success: true, data: task });
});
export default router;
