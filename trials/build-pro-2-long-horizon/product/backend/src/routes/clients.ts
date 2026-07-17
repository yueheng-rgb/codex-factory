import { Router, Request, Response } from 'express';
import { authenticate, authorize, auditLog } from '../middleware/auth';
import * as svc from '../services/clients';
const router = Router();
router.use(authenticate);
router.get('/', (req, res) => { res.json({ success: true, data: svc.listClients(req.user.organizationId) }); });
router.post('/', authorize('admin','manager'), (req, res) => {
  const client = svc.createClient({ ...req.body, organizationId: req.user.organizationId });
  auditLog(req, 'CREATE', 'client', client.id);
  res.json({ success: true, data: client });
});
router.put('/:id', authorize('admin','manager'), (req, res) => {
  const client = svc.updateClient(req.params.id, req.body);
  auditLog(req, 'UPDATE', 'client', req.params.id);
  res.json({ success: true, data: client });
});
router.delete('/:id', authorize('admin'), (req, res) => {
  svc.deleteClient(req.params.id);
  auditLog(req, 'DELETE', 'client', req.params.id);
  res.json({ success: true });
});
export default router;
