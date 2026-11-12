import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/fx.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _features = <(IconData, String)>[
    (Icons.qr_code_scanner, 'باركود سريع'),
    (Icons.point_of_sale, 'نقطة بيع نقدية'),
    (Icons.receipt_long, 'فواتير المبيعات'),
    (Icons.inventory_2_outlined, 'إدارة المخزن'),
    (Icons.photo_camera_outlined, 'صور المنتجات'),
    (Icons.groups_outlined, 'حسابات الموظفين'),
    (Icons.volume_up_outlined, 'أصوات هادئة'),
    (Icons.phone_android, 'بياناتك على جهازك'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('حول محلي'),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          SizedBox(
            height: 370,
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(40)),
              child: AnimatedBackdrop(
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(height: 36),
                      FadeSlideIn(child: AppLogo(size: 96)),
                      FadeSlideIn(
                        delayMs: 200,
                        child: Text('محلي',
                            style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                color: Colors.white)),
                      ),
                      FadeSlideIn(
                        delayMs: 300,
                        child: Text('MAHALLI',
                            style: TextStyle(
                                letterSpacing: 7,
                                fontWeight: FontWeight.w700,
                                color: AppColors.gold)),
                      ),
                      SizedBox(height: 8),
                      FadeSlideIn(
                        delayMs: 420,
                        child: Text('نظام إدارة المحلات والمخازن الذكي',
                            style: TextStyle(color: Colors.white70)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                FadeSlideIn(delayMs: 350, child: _developerCard()),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delayMs: 500,
                  child: Row(children: [
                    _infoCard(Icons.new_releases_outlined, 'الإصدار', '1.0.0'),
                    const SizedBox(width: 12),
                    _infoCard(
                        Icons.payments_outlined, 'طريقة الدفع', 'نقدي فقط'),
                  ]),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(delayMs: 650, child: _featuresCard()),
                const SizedBox(height: 12),
                FadeSlideIn(delayMs: 800, child: _iraqBadge()),
                const SizedBox(height: 20),
                const FadeSlideIn(
                  delayMs: 950,
                  child: Text('© 2026 بلال النعيمي • Belal Alnaimi',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _developerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          Container(
            width: 62,
            height: 62,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.gold, Color(0xFF9C7F44)],
              ),
            ),
            alignment: Alignment.center,
            child: const Text('ب',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('بلال النعيمي',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const Text('Belal Alnaimi',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.mint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('مطوّر التطبيق',
                      style: TextStyle(
                          color: AppColors.emerald,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String value) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Column(children: [
            Icon(icon, color: AppColors.emerald),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(title,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  Widget _featuresCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('مميزات محلي',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in _features)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(f.$1, size: 18, color: AppColors.emerald),
                      const SizedBox(width: 6),
                      Text(f.$2,
                          style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iraqBadge() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gold, Color(0xFFA98B50)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: const [
        Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 34),
        SizedBox(height: 6),
        Text('صنع في العراق',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white)),
        Text('Made in Iraq',
            style: TextStyle(color: Colors.white70, letterSpacing: 2)),
      ]),
    );
  }
}
