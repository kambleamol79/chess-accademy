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
        role: ['admin', 'accountant']
      },
      {
        id: 'my-batch',
        title: 'My batch',
        type: 'item',
        classes: 'nav-item',
        url: '/batches',
        icon: 'ti ti-calendar-event',
        role: ['student']
      },
      {
        id: 'leads',
        title: 'Leads',
        type: 'item',
        classes: 'nav-item',
        url: '/leads',
        icon: 'ti ti-user-search',
        role: ['admin']
      },
      {
        id: 'students',
        title: 'Students',
        type: 'item',
        classes: 'nav-item',
        url: '/students',
        icon: 'ti ti-users',
        role: ['admin']
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
  {
    id: 'training',
    title: 'Training',
    type: 'group',
    icon: 'icon-navigation',
    children: [
      {
        id: 'practice',
        title: 'Chess board',
        type: 'item',
        classes: 'nav-item',
        url: '/practice',
        icon: 'ti ti-chess',
        role: ['admin', 'student']
      },
      {
        id: 'puzzles',
        title: 'Puzzles',
        type: 'item',
        classes: 'nav-item',
        url: '/puzzles',
        icon: 'ti ti-puzzle',
        role: ['admin', 'student']
      },
      // FEATURE: game review — enable when ready
      // {
      //   id: 'game-review',
      //   title: 'Game Review',
      //   type: 'item',
      //   classes: 'nav-item',
      //   url: '/game-review',
      //   icon: 'ti ti-eye',
      //   role: ['admin', 'student']
      // },
      // FEATURE: live arena — enable when ready
      // {
      //   id: 'chess-arena',
      //   title: 'Chess arena',
      //   type: 'item',
      //   classes: 'nav-item',
      //   url: '/chess-arena',
      //   icon: 'ti ti-trophy',
      //   role: ['student']
      // },
      // {
      //   id: 'chess-tournaments',
      //   title: 'Competitions',
      //   type: 'item',
      //   classes: 'nav-item',
      //   url: '/chess-tournaments',
      //   icon: 'ti ti-calendar-event',
      //   role: ['admin']
      // }
    ]
  },
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
