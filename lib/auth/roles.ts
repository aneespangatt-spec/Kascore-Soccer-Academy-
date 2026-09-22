export type PlatformRole = 'super_admin' | 'user';
export type AcademyRole = 'owner' | 'admin' | 'coach' | 'staff' | 'guardian';

export function isAcademyAdmin(role: AcademyRole | null | undefined) {
  return role === 'owner' || role === 'admin';
}
