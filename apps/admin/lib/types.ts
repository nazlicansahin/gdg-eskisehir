export type AdminRole =
  | "member"
  | "team_member"
  | "crew"
  | "organizer"
  | "super_admin";

export type AdminEvent = {
  id: string;
  title: string;
  description?: string | null;
  status: "draft" | "published" | "cancelled";
  capacity: number;
  startsAt: string;
  endsAt: string;
};

export type EventRegistration = {
  id: string;
  userId: string;
  eventId: string;
  qrCodeValue: string;
  status: "active" | "cancelled";
  checkedInAt: string | null;
};

export type AdminUser = {
  id: string;
  displayName: string;
  email: string;
  roles: AdminRole[];
};
