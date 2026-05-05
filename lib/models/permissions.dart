const List<String> allPermissions = [
  // المنتجات
  'products:view_all',
  'products:view_own',
  'products:add',
  'products:edit',
  'products:delete',
  // الطلبات
  'orders:view_all',
  'orders:view_own',
  'orders:accept',
  'orders:reject',
  'orders:ship',
  'orders:deliver',
  // العملاء (للصيدلية: موردين، للشركة: عملاء)
  'customers:view_all',
  'customers:view_own',
  'customers:add',
  'customers:edit',
  'customers:delete',
  // التقارير
  'reports:view_financial',
  'reports:view_sales',
  'reports:view_inventory',
  'reports:view_all',
  // إدارة المستخدمين والفروع
  'users:manage',
  'branches:manage',
  'roles:manage',
  // إدارة المخزون
  'inventory:view',
  'inventory:adjust',
];

// صلاحيات افتراضية لكل دور (يمكن للمدير تعديلها)
const Map<String, List<String>> defaultRolePermissions = {
  'owner': [
    'products:view_all',
    'products:add',
    'products:edit',
    'products:delete',
    'orders:view_all',
    'orders:accept',
    'orders:reject',
    'orders:ship',
    'orders:deliver',
    'customers:view_all',
    'customers:add',
    'customers:edit',
    'customers:delete',
    'reports:view_financial',
    'reports:view_sales',
    'reports:view_inventory',
    'reports:view_all',
    'users:manage',
    'branches:manage',
    'roles:manage',
    'inventory:view',
    'inventory:adjust',
  ],
  'sales_manager': [
    'orders:view_all',
    'orders:accept',
    'orders:reject',
    'orders:ship',
    'customers:view_all',
    'customers:add',
    'customers:edit',
    'reports:view_sales',
  ],
  'accountant': [
    'products:add',
    'products:edit',
    'reports:view_financial',
    'reports:view_sales',
    'inventory:view',
    'orders:view_all',
  ],
  'inventory_manager': [
    'orders:view_own',
    'products:view_all',
    'products:add',
    'products:edit',
    'inventory:view',
    'inventory:adjust',
  ],
  'sales_rep': [
    'customers:view_own',
    'customers:add',
    'orders:view_own',
  ],
  'branch_manager': [
    'orders:view_own',
    'customers:view_own',
    'reports:view_sales',
    'users:manage', // لكن سيتم تقييده بفرعه فقط
  ],
};