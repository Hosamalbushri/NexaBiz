import 'package:flutter/material.dart' as md hide Card, Badge, Divider, TextField, Checkbox, Switch, AppBar, ListTile, Table, Dialog;

import 'package:shadcn_flutter/shadcn_flutter.dart' hide Colors, Row, Column, Flexible, Expanded, Spacer;

/// NexaBiz ERP
/// Professional Mobile Executive Dashboard
///
/// This is a mobile-first dashboard design.
/// It preserves the NexaBiz information hierarchy while
/// adapting the presentation specifically for small screens.
class NexaBizMobileDashboardDesign extends StatefulWidget {
const NexaBizMobileDashboardDesign({super.key});

@override
State<NexaBizMobileDashboardDesign> createState() =>
_NexaBizMobileDashboardDesignState();
}

class _NexaBizMobileDashboardDesignState
extends State<NexaBizMobileDashboardDesign> {
String _selectedPeriod = 'monthly';
int _selectedNavigation = 0;

@override
Widget build(BuildContext context) {
final isAr = Directionality.of(context) == TextDirection.rtl;

return md.Scaffold(
backgroundColor: const md.Color(0xFFF7F8FA),
body: SafeArea(
child: CustomScrollView(
physics: const BouncingScrollPhysics(),
slivers: [
SliverPadding(
padding: const md.EdgeInsets.fromLTRB(16, 12, 16, 24),
sliver: SliverList(
delegate: SliverChildListDelegate([
_buildTopBar(isAr),
const md.SizedBox(height: 22),
_buildGreeting(isAr),
const md.SizedBox(height: 18),
_buildPeriodSelector(isAr),
const md.SizedBox(height: 16),

// Primary KPI
_buildPrimaryRevenueCard(isAr),

const md.SizedBox(height: 14),

// Secondary KPIs
_buildSecondaryKpis(isAr),

const md.SizedBox(height: 14),

// Sales target
_buildSalesTarget(isAr),

const md.SizedBox(height: 24),

// Recent transactions
_buildSectionHeader(
title: isAr ? 'المعاملات الأخيرة' : 'Recent Transactions',
action: isAr ? 'عرض الكل' : 'View All',
onAction: () {},
),

const md.SizedBox(height: 10),

_buildTransactionCard(
isAr: isAr,
id: 'INV-2026-0891',
customer:
isAr ? 'شركة الأمل للتجارة' : 'Al-Amal Trading Co.',
date: isAr ? 'اليوم، 10:42 ص' : 'Today, 10:42 AM',
amount: 'SAR 12,450.00',
status: isAr ? 'مدفوعة' : 'Paid',
statusType: _StatusType.success,
),

const md.SizedBox(height: 10),

_buildTransactionCard(
isAr: isAr,
id: 'INV-2026-0890',
customer:
isAr ? 'مؤسسة التقنية الحديثة' : 'Modern Tech Est.',
date: isAr ? 'أمس، 04:18 م' : 'Yesterday, 04:18 PM',
amount: 'SAR 8,120.00',
status: isAr ? 'معلقة' : 'Pending',
statusType: _StatusType.warning,
),

const md.SizedBox(height: 10),

_buildTransactionCard(
isAr: isAr,
id: 'INV-2026-0889',
customer:
isAr ? 'شركة الرياد المتقدمة' : 'Riyad Advanced Ltd.',
date: isAr ? 'أمس، 01:25 م' : 'Yesterday, 01:25 PM',
amount: 'SAR 24,000.00',
status: isAr ? 'مدفوعة' : 'Paid',
statusType: _StatusType.success,
),

const md.SizedBox(height: 10),

_buildTransactionCard(
isAr: isAr,
id: 'INV-2026-0888',
customer:
isAr ? 'مستودع الشرق الأوسط' : 'Middle East Logistics',
date: isAr ? '07 سبتمبر' : 'Sep 07',
amount: 'SAR 3,450.00',
status: isAr ? 'متأخرة' : 'Overdue',
statusType: _StatusType.danger,
),

const md.SizedBox(height: 26),

// Stock alerts
_buildSectionHeader(
title: isAr ? 'تنبيهات المخزون' : 'Stock Alerts',
action: isAr ? 'عرض الكل' : 'View All',
onAction: () {},
badge: '3',
),

const md.SizedBox(height: 10),

_buildStockAlertCard(
isAr: isAr,
product:
isAr ? 'طابعة ليزر صناعية X1' : 'Industrial Laser Printer X1',
warehouse:
isAr ? 'المستودع الرئيسي - الرياض' : 'Main Warehouse - Riyadh',
currentQty: 2,
minimumQty: 10,
),

const md.SizedBox(height: 10),

_buildStockAlertCard(
isAr: isAr,
product:
isAr ? 'شاشة عرض تفاعلية 65"' : 'Interactive Display 65"',
warehouse: isAr ? 'فرع جدة' : 'Jeddah Branch',
currentQty: 1,
minimumQty: 5,
),

const md.SizedBox(height: 10),

_buildStockAlertCard(
isAr: isAr,
product:
isAr ? 'جهاز نقاط بيع POS X2' : 'POS Terminal X2',
warehouse:
isAr ? 'المستودع الرئيسي - الرياض' : 'Main Warehouse - Riyadh',
currentQty: 3,
minimumQty: 8,
),

const md.SizedBox(height: 24),

_buildQuickActions(isAr),

const md.SizedBox(height: 20),
]),
),
),
],
),
),
bottomNavigationBar: _buildBottomNavigation(isAr),
);
}

// ---------------------------------------------------------------------------
// TOP BAR
// ---------------------------------------------------------------------------

Widget _buildTopBar(bool isAr) {
return md.Row(
children: [
_buildIconButton(
icon: md.Icons.menu_rounded,
onPressed: () {},
tooltip: isAr ? 'القائمة' : 'Menu',
),

const md.SizedBox(width: 12),

md.Expanded(
child: md.Column(
crossAxisAlignment: isAr
? md.CrossAxisAlignment.end
    : md.CrossAxisAlignment.start,
children: [
Text(
'NexaBiz',
style: const md.TextStyle(
fontSize: 20,
fontWeight: md.FontWeight.w800,
letterSpacing: -0.4,
),
),
Text(
isAr ? 'لوحة التحكم' : 'Dashboard',
style: const md.TextStyle(
fontSize: 11,
color: md.Color(0xFF737B87),
fontWeight: md.FontWeight.w500,
),
),
],
),
),

_buildNotificationButton(isAr),

const md.SizedBox(width: 8),

_buildProfileAvatar(),
],
);
}

Widget _buildNotificationButton(bool isAr) {
return md.Stack(
clipBehavior: md.Clip.none,
children: [
_buildIconButton(
icon: md.Icons.notifications_none_rounded,
onPressed: () {},
tooltip: isAr ? 'الإشعارات' : 'Notifications',
),
Positioned(
top: 7,
right: 7,
child: md.Container(
width: 7,
height: 7,
decoration: BoxDecoration(
color: const md.Color(0xFFEF4444),
shape: md.BoxShape.circle,
border: Border.all(
color: const md.Color(0xFFF7F8FA),
width: 1.5,
),
),
),
),
],
);
}

Widget _buildIconButton({
required md.IconData icon,
required VoidCallback onPressed,
required String tooltip,
}) {
return md.Semantics(
button: true,
label: tooltip,
child: md.Material(
color: md.Colors.white,
borderRadius: BorderRadius.circular(12),
child: md.InkWell(
borderRadius: BorderRadius.circular(12),
onTap: onPressed,
child: md.SizedBox(
width: 42,
height: 42,
child: md.Icon(
icon,
size: 21,
color: const md.Color(0xFF343A46),
),
),
),
),
);
}

Widget _buildProfileAvatar() {
return md.Container(
width: 42,
height: 42,
decoration: BoxDecoration(
color: const md.Color(0xFFE9EEF8),
borderRadius: BorderRadius.circular(13),
),
child: const md.Center(
child: md.Text(
'HA',
style: md.TextStyle(
fontSize: 12,
fontWeight: md.FontWeight.w800,
color: md.Color(0xFF3B5CCC),
),
),
),
);
}

// ---------------------------------------------------------------------------
// GREETING
// ---------------------------------------------------------------------------

Widget _buildGreeting(bool isAr) {
return md.Column(
crossAxisAlignment:
isAr ? md.CrossAxisAlignment.end : md.CrossAxisAlignment.start,
children: [
Text(
isAr ? 'صباح الخير' : 'Good morning',
style: const md.TextStyle(
fontSize: 25,
fontWeight: md.FontWeight.w800,
letterSpacing: -0.7,
),
),
const md.SizedBox(height: 5),
Text(
isAr
? 'إليك ملخص نشاط أعمالك اليوم'
    : 'Here is your business activity overview.',
style: const md.TextStyle(
fontSize: 13,
color: md.Color(0xFF737B87),
height: 1.4,
),
),
],
);
}

// ---------------------------------------------------------------------------
// PERIOD
// ---------------------------------------------------------------------------

Widget _buildPeriodSelector(bool isAr) {
return md.Row(
children: [
md.Expanded(
child: md.Container(
height: 46,
decoration: BoxDecoration(
color: md.Colors.white,
borderRadius: BorderRadius.circular(13),
border: Border.all(
color: const md.Color(0xFFE3E7ED),
),
),
child: Select<String>(
value: _selectedPeriod,
onChanged: (value) {
if (value != null) {
setState(() {
_selectedPeriod = value;
});
}
},
itemBuilder: (context, item) => Text(
_periodLabel(item, isAr),
),
popup: SelectPopup.builder(
builder: (context, searchQuery) => SelectItemList(
children: [
SelectItemButton(
value: 'daily',
child: Text(isAr ? 'اليوم' : 'Today'),
),
SelectItemButton(
value: 'weekly',
child: Text(isAr ? 'هذا الأسبوع' : 'This Week'),
),
SelectItemButton(
value: 'monthly',
child: Text(isAr ? 'هذا الشهر' : 'This Month'),
),
],
),
).asBuilder,
),
),
),

const md.SizedBox(width: 10),

md.Material(
color: md.Colors.white,
borderRadius: BorderRadius.circular(13),
child: md.InkWell(
borderRadius: BorderRadius.circular(13),
onTap: () {},
child: md.Container(
width: 46,
height: 46,
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(13),
border: Border.all(
color: const md.Color(0xFFE3E7ED),
),
),
child: const md.Icon(
md.Icons.refresh_rounded,
size: 20,
color: md.Color(0xFF4B5563),
),
),
),
),
],
);
}

String _periodLabel(String value, bool isAr) {
switch (value) {
case 'daily':
return isAr ? 'اليوم' : 'Today';
case 'weekly':
return isAr ? 'هذا الأسبوع' : 'This Week';
default:
return isAr ? 'هذا الشهر' : 'This Month';
}
}

// ---------------------------------------------------------------------------
// PRIMARY KPI
// ---------------------------------------------------------------------------

Widget _buildPrimaryRevenueCard(bool isAr) {
return md.Container(
padding: const md.EdgeInsets.all(20),
decoration: BoxDecoration(
color: const md.Color(0xFF182230),
borderRadius: BorderRadius.circular(20),
boxShadow: [
BoxShadow(
color: md.Colors.black.withValues(alpha: 0.08),
blurRadius: 18,
offset: const md.Offset(0, 8),
),
],
),
child: md.Column(
crossAxisAlignment:
isAr ? md.CrossAxisAlignment.end : md.CrossAxisAlignment.start,
children: [
md.Row(
children: [
md.Container(
width: 40,
height: 40,
decoration: BoxDecoration(
color: md.Colors.white.withValues(alpha: 0.10),
borderRadius: BorderRadius.circular(12),
),
child: const md.Icon(
md.Icons.payments_rounded,
color: md.Colors.white,
size: 20,
),
),

const md.SizedBox(width: 10),

md.Expanded(
child: Text(
isAr ? 'إجمالي المبيعات' : 'Total Revenue',
style: const md.TextStyle(
color: md.Color(0xFFCBD5E1),
fontSize: 13,
fontWeight: md.FontWeight.w500,
),
),
),

md.Container(
padding: const md.EdgeInsets.symmetric(
horizontal: 9,
vertical: 5,
),
decoration: BoxDecoration(
color: const md.Color(0xFF10B981).withValues(alpha: 0.13),
borderRadius: BorderRadius.circular(20),
),
child: const md.Row(
mainAxisSize: md.MainAxisSize.min,
children: [
md.Icon(
md.Icons.trending_up_rounded,
size: 14,
color: md.Color(0xFF34D399),
),
md.SizedBox(width: 3),
md.Text(
'+14.2%',
style: md.TextStyle(
color: md.Color(0xFF34D399),
fontSize: 11,
fontWeight: md.FontWeight.w800,
),
),
],
),
),
],
),

const md.SizedBox(height: 20),

const Text(
'SAR 148,250.00',
style: md.TextStyle(
color: md.Colors.white,
fontSize: 29,
fontWeight: md.FontWeight.w800,
letterSpacing: -0.8,
),
),

const md.SizedBox(height: 6),

Text(
isAr ? 'مقارنة بالفترة السابقة' : 'Compared with previous period',
style: const md.TextStyle(
color: md.Color(0xFF94A3B8),
fontSize: 11,
),
),
],
),
);
}

// ---------------------------------------------------------------------------
// SECONDARY KPIs
// ---------------------------------------------------------------------------

Widget _buildSecondaryKpis(bool isAr) {
return md.Column(
children: [
md.Row(
children: [
md.Expanded(
child: _buildMiniKpi(
title: isAr ? 'الفواتير النشطة' : 'Active Invoices',
value: '42',
change: '+8',
icon: md.Icons.receipt_long_rounded,
iconColor: const md.Color(0xFF3B82F6),
positive: true,
),
),
const md.SizedBox(width: 10),
md.Expanded(
child: _buildMiniKpi(
title: isAr ? 'قيمة المخزون' : 'Inventory Value',
value: '412.9K',
change: '-2.1%',
icon: md.Icons.inventory_2_rounded,
iconColor: const md.Color(0xFFF59E0B),
positive: false,
),
),
],
),
const md.SizedBox(height: 10),
md.Row(
children: [
md.Expanded(
child: _buildMiniKpi(
title: isAr ? 'العملاء الجدد' : 'New Customers',
value: '18',
change: '+22.5%',
icon: md.Icons.people_alt_rounded,
iconColor: const md.Color(0xFF8B5CF6),
positive: true,
),
),
const md.SizedBox(width: 10),
md.Expanded(
child: _buildMiniKpi(
title: isAr ? 'المبيعات اليوم' : 'Today Sales',
value: '18.4K',
change: '+6.8%',
icon: md.Icons.show_chart_rounded,
iconColor: const md.Color(0xFF10B981),
positive: true,
),
),
],
),
],
);
}

Widget _buildMiniKpi({
required String title,
required String value,
required String change,
required md.IconData icon,
required md.Color iconColor,
required bool positive,
}) {
return md.Container(
padding: const md.EdgeInsets.all(15),
decoration: BoxDecoration(
color: md.Colors.white,
borderRadius: BorderRadius.circular(17),
border: Border.all(
color: const md.Color(0xFFE7EAF0),
),
),
child: md.Column(
crossAxisAlignment: md.CrossAxisAlignment.start,
children: [
md.Row(
children: [
md.Container(
width: 34,
height: 34,
decoration: BoxDecoration(
color: iconColor.withValues(alpha: 0.10),
borderRadius: BorderRadius.circular(10),
),
child: md.Icon(
icon,
color: iconColor,
size: 17,
),
),
const md.Spacer(),
md.Icon(
positive
? md.Icons.trending_up_rounded
    : md.Icons.trending_down_rounded,
size: 15,
color: positive
? const md.Color(0xFF10B981)
    : const md.Color(0xFFEF4444),
),
],
),

const md.SizedBox(height: 14),

Text(
title,
style: const md.TextStyle(
fontSize: 11,
color: md.Color(0xFF737B87),
fontWeight: md.FontWeight.w500,
),
),

const md.SizedBox(height: 4),

Text(
value,
style: const md.TextStyle(
fontSize: 21,
fontWeight: md.FontWeight.w800,
letterSpacing: -0.4,
),
),

const md.SizedBox(height: 3),

Text(
change,
style: md.TextStyle(
fontSize: 10,
fontWeight: md.FontWeight.w700,
color: positive
? const md.Color(0xFF10B981)
    : const md.Color(0xFFEF4444),
),
),
],
),
);
}

// ---------------------------------------------------------------------------
// SALES TARGET
// ---------------------------------------------------------------------------

Widget _buildSalesTarget(bool isAr) {
return md.Container(
padding: const md.EdgeInsets.all(17),
decoration: BoxDecoration(
color: md.Colors.white,
borderRadius: BorderRadius.circular(17),
border: Border.all(
color: const md.Color(0xFFE7EAF0),
),
),
child: md.Column(
crossAxisAlignment:
isAr ? md.CrossAxisAlignment.end : md.CrossAxisAlignment.start,
children: [
md.Row(
children: [
md.Container(
width: 35,
height: 35,
decoration: BoxDecoration(
color: const md.Color(0xFF3B82F6).withValues(alpha: 0.10),
borderRadius: BorderRadius.circular(10),
),
child: const md.Icon(
md.Icons.flag_rounded,
color: md.Color(0xFF3B82F6),
size: 18,
),
),
const md.SizedBox(width: 10),
md.Expanded(
child: Text(
isAr ? 'هدف المبيعات الشهري' : 'Monthly Sales Target',
style: const md.TextStyle(
fontSize: 13,
fontWeight: md.FontWeight.w700,
),
),
),
const Text(
'74.2%',
style: md.TextStyle(
fontSize: 15,
fontWeight: md.FontWeight.w800,
color: md.Color(0xFF3B82F6),
),
),
],
),

const md.SizedBox(height: 16),

md.ClipRRect(
borderRadius: BorderRadius.circular(20),
child: const Progress(
progress: 0.742,
),
),

const md.SizedBox(height: 10),

md.Row(
children: [
const Text(
'SAR 148,250',
style: md.TextStyle(
fontSize: 12,
fontWeight: md.FontWeight.w700,
),
),
const md.Spacer(),
Text(
isAr ? 'من SAR 200,000' : 'of SAR 200,000',
style: const md.TextStyle(
fontSize: 11,
color: md.Color(0xFF737B87),
),
),
],
),
],
),
);
}

// ---------------------------------------------------------------------------
// SECTION HEADER
// ---------------------------------------------------------------------------

Widget _buildSectionHeader({
required String title,
required String action,
required VoidCallback onAction,
String? badge,
}) {
return md.Row(
children: [
Text(
title,
style: const md.TextStyle(
fontSize: 17,
fontWeight: md.FontWeight.w800,
letterSpacing: -0.2,
),
),

if (badge != null) ...[
const md.SizedBox(width: 7),
md.Container(
padding: const md.EdgeInsets.symmetric(
horizontal: 7,
vertical: 3,
),
decoration: BoxDecoration(
color: const md.Color(0xFFEF4444).withValues(alpha: 0.10),
borderRadius: BorderRadius.circular(20),
),
child: Text(
badge,
style: const md.TextStyle(
fontSize: 10,
fontWeight: md.FontWeight.w800,
color: md.Color(0xFFEF4444),
),
),
),
],

const md.Spacer(),

md.TextButton(
onPressed: onAction,
child: Text(
action,
style: const md.TextStyle(
fontSize: 12,
fontWeight: md.FontWeight.w700,
color: md.Color(0xFF3B5CCC),
),
),
),
],
);
}

// ---------------------------------------------------------------------------
// TRANSACTION CARD
// ---------------------------------------------------------------------------

Widget _buildTransactionCard({
required bool isAr,
required String id,
required String customer,
required String date,
required String amount,
required String status,
required _StatusType statusType,
}) {
final statusColor = _statusColor(statusType);

return md.Material(
color: md.Colors.white,
borderRadius: BorderRadius.circular(17),
child: md.InkWell(
borderRadius: BorderRadius.circular(17),
onTap: () {},
child: md.Container(
padding: const md.EdgeInsets.all(14),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(17),
border: Border.all(
color: const md.Color(0xFFE7EAF0),
),
),
child: md.Row(
children: [
md.Container(
width: 42,
height: 42,
decoration: BoxDecoration(
color: statusColor.withValues(alpha: 0.10),
borderRadius: BorderRadius.circular(12),
),
child: md.Icon(
md.Icons.receipt_long_rounded,
color: statusColor,
size: 20,
),
),

const md.SizedBox(width: 12),

md.Expanded(
child: md.Column(
crossAxisAlignment: isAr
? md.CrossAxisAlignment.end
    : md.CrossAxisAlignment.start,
children: [
Text(
customer,
maxLines: 1,
overflow: md.TextOverflow.ellipsis,
style: const md.TextStyle(
fontSize: 13,
fontWeight: md.FontWeight.w700,
),
),
const md.SizedBox(height: 4),
Text(
'$id • $date',
maxLines: 1,
overflow: md.TextOverflow.ellipsis,
style: const md.TextStyle(
fontSize: 10,
color: md.Color(0xFF8A929E),
),
),
],
),
),

const md.SizedBox(width: 10),

md.Column(
crossAxisAlignment: isAr
? md.CrossAxisAlignment.start
    : md.CrossAxisAlignment.end,
children: [
Text(
amount,
style: const md.TextStyle(
fontSize: 12,
fontWeight: md.FontWeight.w800,
),
),
const md.SizedBox(height: 6),
_buildStatusBadge(
status: status,
color: statusColor,
),
],
),
],
),
),
),
);
}

Widget _buildStatusBadge({
required String status,
required md.Color color,
}) {
return md.Container(
padding: const md.EdgeInsets.symmetric(
horizontal: 8,
vertical: 4,
),
decoration: BoxDecoration(
color: color.withValues(alpha: 0.10),
borderRadius: BorderRadius.circular(20),
),
child: Text(
status,
style: md.TextStyle(
color: color,
fontSize: 9,
fontWeight: md.FontWeight.w800,
),
),
);
}

// ---------------------------------------------------------------------------
// STOCK ALERT
// ---------------------------------------------------------------------------

Widget _buildStockAlertCard({
required bool isAr,
required String product,
required String warehouse,
required int currentQty,
required int minimumQty,
}) {
final percentage = currentQty / minimumQty;

return md.Material(
color: md.Colors.white,
borderRadius: BorderRadius.circular(17),
child: md.InkWell(
borderRadius: BorderRadius.circular(17),
onTap: () {},
child: md.Container(
padding: const md.EdgeInsets.all(14),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(17),
border: Border.all(
color: const md.Color(0xFFF0D9D9),
),
),
child: md.Row(
children: [
md.Container(
width: 42,
height: 42,
decoration: BoxDecoration(
color: const md.Color(0xFFEF4444).withValues(alpha: 0.09),
borderRadius: BorderRadius.circular(12),
),
child: const md.Icon(
md.Icons.warning_amber_rounded,
color: md.Color(0xFFEF4444),
size: 21,
),
),

const md.SizedBox(width: 12),

md.Expanded(
child: md.Column(
crossAxisAlignment: isAr
? md.CrossAxisAlignment.end
    : md.CrossAxisAlignment.start,
children: [
Text(
product,
maxLines: 1,
overflow: md.TextOverflow.ellipsis,
style: const md.TextStyle(
fontSize: 12,
fontWeight: md.FontWeight.w700,
),
),
const md.SizedBox(height: 4),
Text(
warehouse,
maxLines: 1,
overflow: md.TextOverflow.ellipsis,
style: const md.TextStyle(
fontSize: 10,
color: md.Color(0xFF8A929E),
),
),
const md.SizedBox(height: 8),
md.ClipRRect(
borderRadius: BorderRadius.circular(20),
child: md.LinearProgressIndicator(
value: percentage.clamp(0.0, 1.0),
minHeight: 4,
backgroundColor:
const md.Color(0xFFEF4444).withValues(alpha: 0.08),
valueColor: const md.AlwaysStoppedAnimation(
md.Color(0xFFEF4444),
),
),
),
],
),
),

const md.SizedBox(width: 12),

md.Column(
crossAxisAlignment: md.CrossAxisAlignment.end,
children: [
Text(
'$currentQty',
style: const md.TextStyle(
color: md.Color(0xFFEF4444),
fontSize: 17,
fontWeight: md.FontWeight.w800,
),
),
Text(
'/ $minimumQty',
style: const md.TextStyle(
color: md.Color(0xFF8A929E),
fontSize: 9,
fontWeight: md.FontWeight.w600,
),
),
],
),
],
),
),
),
);
}

// ---------------------------------------------------------------------------
// QUICK ACTIONS
// ---------------------------------------------------------------------------

Widget _buildQuickActions(bool isAr) {
return md.Container(
padding: const md.EdgeInsets.all(16),
decoration: BoxDecoration(
color: md.Colors.white,
borderRadius: BorderRadius.circular(17),
border: Border.all(
color: const md.Color(0xFFE7EAF0),
),
),
child: md.Column(
crossAxisAlignment:
isAr ? md.CrossAxisAlignment.end : md.CrossAxisAlignment.start,
children: [
Text(
isAr ? 'إجراءات سريعة' : 'Quick Actions',
style: const md.TextStyle(
fontSize: 15,
fontWeight: md.FontWeight.w800,
),
),

const md.SizedBox(height: 14),

md.Row(
children: [
md.Expanded(
child: _buildQuickAction(
icon: md.Icons.add_shopping_cart_rounded,
title: isAr ? 'فاتورة بيع' : 'Sale',
color: const md.Color(0xFF3B82F6),
onTap: () {},
),
),
const md.SizedBox(width: 10),
md.Expanded(
child: _buildQuickAction(
icon: md.Icons.person_add_alt_1_rounded,
title: isAr ? 'عميل' : 'Customer',
color: const md.Color(0xFF8B5CF6),
onTap: () {},
),
),
const md.SizedBox(width: 10),
md.Expanded(
child: _buildQuickAction(
icon: md.Icons.inventory_2_rounded,
title: isAr ? 'منتج' : 'Product',
color: const md.Color(0xFF10B981),
onTap: () {},
),
),
],
),
],
),
);
}

Widget _buildQuickAction({
required md.IconData icon,
required String title,
required md.Color color,
required VoidCallback onTap,
}) {
return md.Material(
color: color.withValues(alpha: 0.07),
borderRadius: BorderRadius.circular(13),
child: md.InkWell(
borderRadius: BorderRadius.circular(13),
onTap: onTap,
child: md.Padding(
padding: const md.EdgeInsets.symmetric(vertical: 12),
child: md.Column(
children: [
md.Icon(
icon,
color: color,
size: 21,
),
const md.SizedBox(height: 6),
Text(
title,
textAlign: md.TextAlign.center,
style: const md.TextStyle(
fontSize: 10,
fontWeight: md.FontWeight.w700,
),
),
],
),
),
),
);
}

// ---------------------------------------------------------------------------
// BOTTOM NAVIGATION
// ---------------------------------------------------------------------------

Widget _buildBottomNavigation(bool isAr) {
final items = [
(
icon: md.Icons.dashboard_rounded,
label: isAr ? 'الرئيسية' : 'Home',
),
(
icon: md.Icons.receipt_long_rounded,
label: isAr ? 'المبيعات' : 'Sales',
),
(
icon: md.Icons.inventory_2_rounded,
label: isAr ? 'المخزون' : 'Inventory',
),
(
icon: md.Icons.more_horiz_rounded,
label: isAr ? 'المزيد' : 'More',
),
];

return md.Container(
decoration: BoxDecoration(
color: md.Colors.white,
border: Border(
top: BorderSide(
color: const md.Color(0xFFE7EAF0),
),
),
),
child: SafeArea(
top: false,
child: md.Padding(
padding: const md.EdgeInsets.fromLTRB(10, 8, 10, 8),
child: md.Row(
children: List.generate(
items.length,
(index) {
final selected = _selectedNavigation == index;

return md.Expanded(
child: md.Semantics(
button: true,
selected: selected,
label: items[index].label,
child: md.InkWell(
borderRadius: BorderRadius.circular(14),
onTap: () {
setState(() {
_selectedNavigation = index;
});
},
child: md.Padding(
padding: const md.EdgeInsets.symmetric(
vertical: 6,
),
child: md.Column(
mainAxisSize: md.MainAxisSize.min,
children: [
md.AnimatedContainer(
duration: const Duration(milliseconds: 180),
width: selected ? 42 : 34,
height: 32,
decoration: BoxDecoration(
color: selected
? const md.Color(0xFF3B5CCC)
    .withValues(alpha: 0.10)
    : md.Colors.transparent,
borderRadius: BorderRadius.circular(10),
),
child: md.Icon(
items[index].icon,
size: 20,
color: selected
? const md.Color(0xFF3B5CCC)
    : const md.Color(0xFF8A929E),
),
),
const md.SizedBox(height: 3),
Text(
items[index].label,
style: md.TextStyle(
fontSize: 9,
fontWeight: selected
? md.FontWeight.w800
    : md.FontWeight.w500,
color: selected
? const md.Color(0xFF3B5CCC)
    : const md.Color(0xFF8A929E),
),
),
],
),
),
),
),
);
},
),
),
),
),
);
}

// ---------------------------------------------------------------------------
// HELPERS
// ---------------------------------------------------------------------------

md.Color _statusColor(_StatusType type) {
switch (type) {
case _StatusType.success:
return const md.Color(0xFF10B981);
case _StatusType.warning:
return const md.Color(0xFFF59E0B);
case _StatusType.danger:
return const md.Color(0xFFEF4444);
}
}
}

enum _StatusType {
success,
warning,
danger,
}

