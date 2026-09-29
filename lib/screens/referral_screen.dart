import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/api_service.dart';

class ReferralScreen extends StatefulWidget {
  final int customerId;

  const ReferralScreen({super.key, required this.customerId});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  static const Color skyBlue = Color(0xFF29B6F6);

  bool _isLoading = true;
  String? _errorMessage;

  String _referralCode = '';
  double _storeCreditBalance = 0.0;

  List<dynamic> _referrals = [];
  Map<String, dynamic>? _receivedReferral;

  @override
  void initState() {
    super.initState();
    _loadReferralData();
  }

  Future<void> _loadReferralData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getReferrals(widget.customerId);

      if (!mounted) {
        return;
      }

      setState(() {
        _referralCode = data['referral_code']?.toString() ?? '';

        _storeCreditBalance = _toDouble(data['store_credit_balance']);

        _referrals = data['referrals'] is List
            ? List<dynamic>.from(data['referrals'])
            : [];

        _receivedReferral = data['received_referral'] is Map
            ? Map<String, dynamic>.from(data['received_referral'])
            : null;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  String _formatAmount(double amount) {
    return '₦${amount.toStringAsFixed(2).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}';
  }

  Future<void> _copyReferralCode() async {
    if (_referralCode.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: _referralCode));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Referral code copied.')));
  }

  Future<void> _shareOnWhatsApp() async {
    if (_referralCode.isEmpty) {
      return;
    }

    final message =
        'Join me on Levetor Hub and get ₦1,000 store credit when you qualify! '
        'Use my referral code: $_referralCode';

    final url = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(message)}',
    );

    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open WhatsApp.')));
    }
  }

  Widget _buildReferralCodeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF29B6F6), Color(0xFF0288D1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.white, size: 28),
              SizedBox(width: 10),
              Text(
                'Refer & Earn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Invite friends to Levetor Hub and earn store credit.',
            style: TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your referral code',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _referralCode.isEmpty ? 'Unavailable' : _referralCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _referralCode.isEmpty ? null : _copyReferralCode,
                  color: Colors.white,
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy referral code',
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _referralCode.isEmpty ? null : _shareOnWhatsApp,
              icon: const Icon(Icons.chat),
              label: const Text('Share on WhatsApp'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: skyBlue,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: skyBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: skyBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Store Credit',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatAmount(_storeCreditBalance),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How it works',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildStep(
            number: '1',
            title: 'Share your code',
            description: 'Invite a friend using your referral code.',
          ),
          _buildStep(
            number: '2',
            title: 'Your friend registers',
            description:
                'Your friend creates a Levetor Hub account with your code.',
          ),
          _buildStep(
            number: '3',
            title: 'Qualifying order',
            description: 'Your friend completes one successful paid order of at least ₦50,000.',
          ),
          _buildStep(
            number: '4',
            title: 'Both earn ₦1,000',
            description: '₦1,000 store credit is added to both accounts.',
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: skyBlue,
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralItem(Map<String, dynamic> referral) {
    final status = referral['status']?.toString() ?? 'Pending';

    final name =
        referral['referee_name']?.toString() ??
        referral['fullname']?.toString() ??
        referral['referee_customer_id']?.toString() ??
        'Referred customer';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: skyBlue.withValues(alpha: 0.10),
            child: const Icon(Icons.person_outline, color: skyBlue),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  'Status: $status',
                  style: TextStyle(
                    color: status == 'Rewarded' ? Colors.green : Colors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Referrals',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_referrals.isEmpty)
            Text(
              'You have not referred anyone yet.',
              style: TextStyle(color: Colors.grey.shade700),
            )
          else
            ..._referrals.whereType<Map>().map(
              (referral) =>
                  _buildReferralItem(Map<String, dynamic>.from(referral)),
            ),
        ],
      ),
    );
  }

  Widget _buildReceivedReferralSection() {
    if (_receivedReferral == null) {
      return const SizedBox.shrink();
    }

    final status = _receivedReferral!['status']?.toString() ?? 'Pending';

    final referrerName =
        _receivedReferral!['referrer_name']?.toString() ??
        _receivedReferral!['referrer_customer_id']?.toString() ??
        'Levetor Hub customer';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Referral',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Text(
            'Referred by: $referrerName',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          Text(
            'Status: $status',
            style: TextStyle(
              color: status == 'Rewarded' ? Colors.green : Colors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text(
          'Refer & Earn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadReferralData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: skyBlue))
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadReferralData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadReferralData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildReferralCodeCard(),
                  const SizedBox(height: 15),
                  _buildRewardCard(),
                  const SizedBox(height: 15),
                  _buildHowItWorks(),
                  const SizedBox(height: 15),
                  _buildReferralsSection(),
                  const SizedBox(height: 15),
                  _buildReceivedReferralSection(),
                  const SizedBox(height: 25),
                ],
              ),
            ),
    );
  }
}
