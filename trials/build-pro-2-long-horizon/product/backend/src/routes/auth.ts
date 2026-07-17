import { Router, Request, Response } from 'express';
import { registerUser, loginUser } from '../services/auth';
const router = Router();
router.post('/register', (req: Request, res: Response) => {
  try {
    const { email, name, password, role, organizationId } = req.body;
    const user = registerUser(email, name, password, role, organizationId);
    res.json({ success: true, data: user });
  } catch (e: any) { res.status(400).json({ success: false, error: e.message }); }
});
router.post('/login', (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;
    const result = loginUser(email, password);
    res.json({ success: true, data: result });
  } catch (e: any) { res.status(401).json({ success: false, error: e.message }); }
});
export default router;
