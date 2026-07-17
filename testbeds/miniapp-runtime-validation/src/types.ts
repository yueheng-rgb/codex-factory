export interface MiniappSession { openid: string; sessionToken: string; userId: string; }
export interface UserData { userId: string; nickname: string; avatar: string; orders: string[]; }
export interface FormSubmission { userId: string; title: string; content: string; phone?: string; }
export interface PaymentCallback { transactionId: string; openid: string; amount: number; status: string; }
export interface UploadMeta { userId: string; fileName: string; mimeType: string; size: number; }
export interface AdminUser { userId: string; role: string; }
export const ALLOWED_MIME_TYPES = ["image/jpeg","image/png","image/webp","application/pdf"];
export const MAX_UPLOAD_SIZE = 5 * 1024 * 1024;
