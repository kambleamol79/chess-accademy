export interface NavigationItem {
  id: string;
  title: string;
  type: 'item' | 'collapse' | 'group';
  translate?: string;
  icon?: string;
  hidden?: boolean;
  url?: string;
  classes?: string;
  external?: boolean;
  target?: boolean;
  breadcrumbs?: boolean;
  children?: NavigationItem[];
  role?: string[];
  isMainParent?: boolean;
}

export const NavigationItems: NavigationItem[] = [
  {
    id: 'main',
    title: 'Main',
    type: 'group',
    icon: 'icon-navigation',
    children: [
      {
        id: 'dashboard',
        title: 'Dashboard',
        type: 'item',
        classes: 'nav-item',
        url: '/dashboard',
        icon: 'ti ti-dashboard',
        role: ['admin', 'coach', 'student', 'accountant']
      }
    ]
  },
  {
    id: 'academy',
    title: 'Academy',
    type: 'group',
    icon: 'icon-navigation',
    children: [
      {
        id: 'batches',
        title: 'Batches',
        type: 'item',
        classes: 'nav-item',
        url: '/batches',
        icon: 'ti ti-calendar-event',
        role: ['admin', 'coach', 'student', 'accountant']
      },
      {
        id: 'students',
        title: 'Students',
        type: 'item',
        classes: 'nav-item',
        url: '/students',
        icon: 'ti ti-users',
        role: ['admin', 'coach']
      },
      {
        id: 'coaches',
        title: 'Coaches',
        type: 'item',
        classes: 'nav-item',
        url: '/coaches',
        icon: 'ti ti-user-star',
        role: ['admin']
      }
    ]
  },
  /*{
    id: 'training',
    title: 'Training',
    type: 'group',
    icon: 'icon-navigation',
    children: [
      {
        id: 'puzzles',
        title: 'Puzzles',
        type: 'item',
        classes: 'nav-item',
        url: '/puzzles',
        icon: 'ti ti-chess',
        role: ['admin', 'coach', 'student']
      },
      {
        id: 'game-review',
        title: 'Game Review',
        type: 'item',
        classes: 'nav-item',
        url: '/game-review',
        icon: 'ti ti-eye',
        role: ['admin', 'coach', 'student']
      },
      {
        id: 'materials',
        title: 'Class Materials',
        type: 'item',
        classes: 'nav-item',
        url: '/materials',
        icon: 'ti ti-book',
        role: ['admin', 'coach', 'student']
      }
    ]
  },*/
  {
    id: 'finance',
    title: 'Finance',
    type: 'group',
    icon: 'icon-navigation',
    children: [
      {
        id: 'billing',
        title: 'Billing',
        type: 'item',
        classes: 'nav-item',
        url: '/billing',
        icon: 'ti ti-receipt',
        role: ['admin', 'accountant']
      }
    ]
  },
  {
    id: 'system',
    title: 'System',
    type: 'group',
    icon: 'icon-navigation',
    children: [
      {
        id: 'settings',
        title: 'Settings',
        type: 'item',
        classes: 'nav-item',
        url: '/settings',
        icon: 'ti ti-settings',
        role: ['admin']
      }
    ]
  }
];
