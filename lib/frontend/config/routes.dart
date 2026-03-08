/// Application Routes
class AppRoutes {
  AppRoutes._();

  // Root
  static const String home = '/';
  
  // Authentication
  static const String login = '/login';
  
  // Dashboard
  static const String dashboard = '/dashboard';
  
  // Customers
  static const String customers = '/customers';
  static const String customerDetails = '/customers/:id';
  static const String addCustomer = '/customers/add';
  static const String editCustomer = '/customers/:id/edit';
  static const String customerStatement = '/customers/:id/statement';
  
  // Invoices
  static const String invoices = '/invoices';
  static const String invoiceDetails = '/invoices/:id';
  static const String addInvoice = '/invoices/add';
  static const String editInvoice = '/invoices/:id/edit';
  
  // Payments
  static const String payments = '/payments';
  static const String addReceipt = '/payments/receipt/add';
  static const String addPayment = '/payments/payment/add';
  
  // Products
  static const String products = '/products';
  static const String addProduct = '/products/add';
  static const String editProduct = '/products/:id/edit';
  
  // Suppliers
  static const String suppliers = '/suppliers';
  static const String addSupplier = '/suppliers/add';
  static const String editSupplier = '/suppliers/:id/edit';
  static const String supplierStatement = '/suppliers/:id/statement';
  
  // Reports
  static const String reports = '/reports';
  static const String profitLoss = '/reports/profit-loss';
  static const String aging = '/reports/aging';
  static const String salesReport = '/reports/sales';
  
  // Settings
  static const String settings = '/settings';
  static const String users = '/settings/users';
  static const String backup = '/settings/backup';
  static const String auditLog = '/settings/audit-log';
  
  // Helper method to build route with parameter
  static String buildRoute(String route, Map<String, String> params) {
    var result = route;
    params.forEach((key, value) {
      result = result.replaceAll(':$key', value);
    });
    return result;
  }
}
