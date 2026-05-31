import { NavigationItem } from 'src/app/theme/layout/admin/navigation/navigation';
import { UserRole } from '../models/api.model';

/** Nav item ids allowed for students (excludes removed features like materials). */
const STUDENT_NAV_IDS = new Set(['dashboard', 'my-batch', 'practice', 'puzzles']);

/** Legacy / removed ids — never show even if re-added to NavigationItems by mistake. */
const REMOVED_NAV_IDS = new Set(['materials', 'chess-arena', 'chess-tournaments', 'game-review']);

export function filterNavigationByRole(items: NavigationItem[], role: UserRole | null): NavigationItem[] {
  if (!role) {
    return [];
  }

  return items
    .map((item) => {
      if (item.type === 'group' || item.type === 'collapse') {
        const children = item.children ? filterNavigationByRole(item.children, role) : [];
        if (children.length === 0) {
          return null;
        }
        return { ...item, children };
      }

      if (REMOVED_NAV_IDS.has(item.id)) {
        return null;
      }

      if (role === 'student') {
        if (!STUDENT_NAV_IDS.has(item.id)) {
          return null;
        }
      } else if (item.role && !item.role.includes(role)) {
        return null;
      }

      return item;
    })
    .filter((item): item is NavigationItem => item !== null);
}
