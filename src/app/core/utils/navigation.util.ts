import { NavigationItem } from 'src/app/theme/layout/admin/navigation/navigation';
import { UserRole } from '../models/api.model';

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
      if (item.role && !item.role.includes(role)) {
        return null;
      }
      return item;
    })
    .filter((item): item is NavigationItem => item !== null);
}
