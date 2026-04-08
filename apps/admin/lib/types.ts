export type AdminRole =
  | "member"
  | "team_member"
  | "crew"
  | "organizer"
  | "super_admin";

export type AdminEvent = {
  id: string;
  title: string;
  status: "draft" | "published" | "cancelled";
  startsAt: string;
};

export type EventRegistration = {
  id: string;
  attendeeName: string;
  attendeeEmail: string;
  status: "active" | "cancelled";
  checkedInAt: string | null;
};

export type AdminUser = {
  id: string;
  displayName: string;
  email: string;
  roles: AdminRole[];
};
