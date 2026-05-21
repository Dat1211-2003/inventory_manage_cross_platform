import 'package:flutter/material.dart';
import 'dart:io';
import 'package:inventory_manage/routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  bool get isDesktop => Platform.isWindows;

  @override
  Widget build(BuildContext context) {
    return isDesktop ? const DesktopHomeScreen() : const MobileHomeScreen();
  }
}

////////////////////////////////////////////////////////////
/// MOBILE UI
////////////////////////////////////////////////////////////

class MobileHomeScreen extends StatelessWidget {
  const MobileHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,

            children: [
              dashboardCard(
                context,
                icon: Icons.widgets,
                title: "Sản phẩm",
                color: Colors.green,
                onTap: () => Navigator.pushNamed(context, AppRoutes.product),
              ),

              dashboardCard(
                context,
                icon: Icons.input_outlined,
                title: "Nhập hàng",
                color: Colors.blue,
                onTap: () => Navigator.pushNamed(context, AppRoutes.import_),
              ),

              dashboardCard(
                context,
                icon: Icons.sell,
                title: "Bán hàng",
                color: Colors.red,
                onTap: () => Navigator.pushNamed(context, AppRoutes.sale),
              ),

              dashboardCard(
                context,
                icon: Icons.bar_chart,
                title: "Báo cáo",
                color: Colors.purple,
                onTap: () => Navigator.pushNamed(context, AppRoutes.statistic),
              ),

              dashboardCard(
                context,
                icon: Icons.qr_code_scanner,
                title: "Quét mã",
                color: Colors.lightBlueAccent,
                onTap: () => Navigator.pushNamed(context, AppRoutes.scan),
              ),

              dashboardCard(
                context,
                icon: Icons.account_circle,
                title: "Tài khoản",
                color: Colors.grey,
                onTap: () => Navigator.pushNamed(context, AppRoutes.user),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// DESKTOP UI
class DesktopHomeScreen extends StatelessWidget {
  const DesktopHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),

      body: Row(
        children: [
          Container(
            width: 250,
            padding: const EdgeInsets.all(20),
            color: Colors.white,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                const Text(
                  "Inventory Manager",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 40),

                sidebarButton(
                  icon: Icons.widgets,
                  title: "Sản phẩm",
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.product),
                ),

                sidebarButton(
                  icon: Icons.input_outlined,
                  title: "Nhập hàng",
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.import_),
                ),

                sidebarButton(
                  icon: Icons.sell,
                  title: "Bán hàng",
                  color: Colors.red,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.sale),
                ),

                sidebarButton(
                  icon: Icons.bar_chart,
                  title: "Báo cáo",
                  color: Colors.purple,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.statistic),
                ),

                sidebarButton(
                  icon: Icons.account_circle,
                  title: "Tài khoản",
                  color: Colors.grey,
                  onTap: () => Navigator.pushNamed(context, AppRoutes.user),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(30),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dashboard",
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Quản lý hàng hóa và thống kê hệ thống",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),

                  const SizedBox(height: 30),

                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 3,
                      crossAxisSpacing: 25,
                      mainAxisSpacing: 25,
                      childAspectRatio: 1.4,

                      children: [
                        desktopCard(
                          context,
                          icon: Icons.widgets,
                          title: "Sản phẩm",
                          subtitle: "Quản lý danh sách sản phẩm",
                          color: Colors.green,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.product),
                        ),

                        desktopCard(
                          context,
                          icon: Icons.input_outlined,
                          title: "Nhập hàng",
                          subtitle: "Quản lý nhập kho",
                          color: Colors.blue,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.import_),
                        ),

                        desktopCard(
                          context,
                          icon: Icons.sell,
                          title: "Bán hàng",
                          subtitle: "Tạo và quản lý hóa đơn",
                          color: Colors.red,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.sale),
                        ),

                        desktopCard(
                          context,
                          icon: Icons.bar_chart,
                          title: "Báo cáo",
                          subtitle: "Thống kê doanh thu",
                          color: Colors.purple,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.statistic),
                        ),

                        desktopCard(
                          context,
                          icon: Icons.account_circle,
                          title: "Tài khoản",
                          subtitle: "Thông tin người dùng",
                          color: Colors.grey,
                          onTap: () =>
                              Navigator.pushNamed(context, AppRoutes.user),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget dashboardCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: onTap,

    child: Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),

        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,

        children: [
          Container(
            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),

            child: Icon(icon, color: Colors.white, size: 33),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ],
      ),
    ),
  );
}

Widget desktopCard(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required Color color,
  required VoidCallback onTap,
}) {
  return InkWell(
    borderRadius: BorderRadius.circular(25),
    onTap: onTap,

    child: Container(
      padding: const EdgeInsets.all(25),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),

        boxShadow: const [
          BoxShadow(
            blurRadius: 15,
            color: Colors.black12,
            offset: Offset(0, 5),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Container(
            padding: const EdgeInsets.all(18),

            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(18),
            ),

            child: Icon(icon, color: color, size: 42),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                subtitle,
                style: const TextStyle(fontSize: 15, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget sidebarButton({
  required IconData icon,
  required String title,
  required Color color,
  required VoidCallback onTap,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),

    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),

        child: Row(
          children: [
            Icon(icon, color: color),

            const SizedBox(width: 14),

            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}
