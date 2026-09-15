import 'package:flutter/material.dart';

class WelfareInterventionTab extends StatefulWidget {
  const WelfareInterventionTab({super.key});

  @override
  State<WelfareInterventionTab> createState() => _WelfareInterventionTabState();
}

class _WelfareInterventionTabState extends State<WelfareInterventionTab> {
  final List<Map<String, dynamic>> _statutoryRemedies = [
    {
      'title': 'Emergency Subsistence Relief (50% Milestone)',
      'section': 'SC/ST (PoA) Rules, Annexure I',
      'amount': '₹ 1,00,000 Disbursement',
      'status': 'APPROVED & DISBURSED',
      'statusColor': const Color(0xFF059669),
      'icon': Icons.account_balance_wallet,
    },
    {
      'title': 'Safe-House Temporary Relocation',
      'section': 'Witness Protection Scheme, 2018 (Cat II)',
      'amount': 'District Shelter Home / Govt Quarter',
      'status': 'RECOMMENDED & READY',
      'statusColor': const Color(0xFF2563EB),
      'icon': Icons.home_work,
    },
    {
      'title': 'Armed Police Court Escort',
      'section': 'Section 15A(10) SC/ST (PoA) Act',
      'amount': '2 Constable Protection Team',
      'status': 'DISPATCHED FOR SEP 16',
      'statusColor': const Color(0xFF7C3AED),
      'icon': Icons.local_police,
    },
    {
      'title': 'Specialized Clinical Trauma Therapy',
      'section': 'Mental Healthcare Act, 2017 (Sec 18)',
      'amount': 'Weekly Tele-Psychiatry Sessions',
      'status': 'ACTIVE IN PROGRESS',
      'statusColor': const Color(0xFF059669),
      'icon': Icons.psychology,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Compensation & Welfare Disbursement Tracker
          _buildCompensationTrackerCard(),
          const SizedBox(height: 20),

          // Prescriptive Relief Matcher Section
          _buildPrescriptiveReliefSection(),
          const SizedBox(height: 20),

          // DLSA & Social Welfare Officer Referral Banner
          _buildDlsaReferralCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCompensationTrackerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.monetization_on, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text(
                    'Relief Disbursement & Wellness Curve',
                    style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(10)),
                child: const Text('STAGE 2 / 3 DISBURSED', style: TextStyle(color: Color(0xFF047857), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Syncs disbursement cycles of statutory relief funds alongside psychological wellness curves to prevent severe economic distress.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 16),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Disbursement Progress (SC/ST PoA Statutory Fund)', style: TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.w600)),
                  Text('₹ 2,00,000 / ₹ 4,00,000', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const LinearProgressIndicator(
                  value: 0.50,
                  backgroundColor: Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptiveReliefSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text(
                'Prescriptive Relief Matcher (Statutory Mandates)',
                style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Rule-based AI engine generating statutory remedies under SC/ST (PoA) Act Rules based on DDI risk level.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
          const SizedBox(height: 16),

          Column(
            children: _statutoryRemedies.map((item) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: (item['statusColor'] as Color).withValues(alpha: 0.15),
                      child: Icon(item['icon'] as IconData, color: item['statusColor'] as Color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title'] as String, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text('${item["section"]} • ${item["amount"]}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: (item['statusColor'] as Color).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        item['status'] as String,
                        style: TextStyle(color: item['statusColor'] as Color, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDlsaReferralCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.gavel, color: Color(0xFF4F46E5)),
              SizedBox(width: 8),
              Text(
                'District Legal Services Authority (DLSA) Portal',
                style: TextStyle(color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Assigned Legal Aid Officer: Advocate S. Sharma (Varanasi DLSA Cell). SLA Response Timeout: 15 Mins.',
            style: TextStyle(color: Color(0xFF334155), fontSize: 11),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.call, size: 16),
                  label: const Text('CALL DLSA OFFICER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4F46E5),
                    side: const BorderSide(color: Color(0xFF4F46E5)),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.send_outlined, size: 16),
                  label: const Text('DISPATCH REFERRAL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
