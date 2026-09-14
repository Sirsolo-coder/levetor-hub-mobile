import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const Color skyBlue = Color(0xFF29B6F6);
  static const Color darkBlue = Color(0xFF0288D1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'About Us',
          style: TextStyle(
            color: skyBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: skyBlue,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Image.asset(
              'assets/app_logo.jpg',
              height: 110,
              width: 110,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.devices,
                  size: 90,
                  color: skyBlue,
                );
              },
            ),

            const SizedBox(height: 15),

            const Text(
              'Levetor Hub',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: skyBlue,
              ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Every Gadget You Love, One Hub.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: darkBlue,
              ),
            ),

            const SizedBox(height: 25),

            _infoCard(
              icon: Icons.storefront_outlined,
              title: 'Who We Are',
              text:
                  'Levetor Hub is a technology and electronics platform designed to make it easier to discover and purchase gadgets, electronics, accessories and technology products from one convenient hub.',
            ),

            _infoCard(
              icon: Icons.devices_other,
              title: 'What We Offer',
              text:
                  'We provide access to phones, computers, tablets, accessories, audio devices, gaming products, home appliances, software, solar and power products, and other technology solutions.',
            ),

            _infoCard(
              icon: Icons.verified_outlined,
              title: 'Our Goal',
              text:
                  'Our goal is to provide customers with quality technology products, a convenient shopping experience and reliable customer support.',
            ),

            _infoCard(
              icon: Icons.favorite_border,
              title: 'Why Levetor Hub?',
              text:
                  'We bring the gadgets and technology you love together in one place, making it easier to find what you need and get support when you need it.',
            ),

            const SizedBox(height: 5),

            const Text(
              'Nationwide delivery, secure payments, and a commitment to customer satisfaction are at the core of our service.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'Levetor Hub',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Technology. Convenience. One Hub.',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String text,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: skyBlue.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: skyBlue,
                size: 25,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    text,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.45,
                      fontSize: 13.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}