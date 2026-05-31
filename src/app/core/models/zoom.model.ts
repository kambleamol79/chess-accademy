export interface ZoomJoinSignature {
  signature: string;
  sdkKey: string;
  meetingNumber: string;
  password: string;
  userName: string;
  role: number;
  topic: string;
  zak?: string | null;
  hostStartUrl?: string | null;
  hostWarning?: string | null;
  setupHint?: string;
}
