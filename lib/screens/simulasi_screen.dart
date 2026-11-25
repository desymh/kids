import 'package:flutter/material.dart';
import '../core/fsm_controller.dart';

class SimulasiScreen extends StatefulWidget {
  const SimulasiScreen({super.key});

  @override
  State<SimulasiScreen> createState() => _SimulasiScreenState();
}

class _SimulasiScreenState extends State<SimulasiScreen> {
  final IbadahSimulationFSM _fsm = IbadahSimulationFSM(steps: ['niat', 'basuh_tangan', 'berkumur', 'istinsyaq', 'basuh_muka', 'basuh_tangan_kanan', 'basuh_tangan_kiri', 'usap_kepala', 'usap_telinga', 'basuh_kaki']);
  int _nyawa = 3;
  int _poin = 0;

  int _selectedIndex = 1;

  final List<_WudhuStep> steps = const [
    _WudhuStep('niat', 'Niat', 'assets/images/wudhu_niat.png'),
    _WudhuStep('basuh_tangan', 'Membasuh\nTangan', 'assets/images/wudhu_tangan.png'),
    _WudhuStep('mengusap_kepala', 'Mengusap\nKepala', 'assets/images/wudhu_kepala.png'),
    _WudhuStep('basuh_kaki', 'Membasuh\nKaki', 'assets/images/wudhu_kaki.png'),
  ];

  void _onStepTap(int index) {
    setState(() => _selectedIndex = index);
    if (!_fsm.validasiLangkah(index)) {
      _nyawa -= 1;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Urutan salah! Nyawa: $_nyawa'), backgroundColor: Colors.red));
    } else {
      _poin += 20;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Benar! Poin: $_poin'), backgroundColor: Colors.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFDDF6EC), Color(0xFFCBEFE2), Color(0xFF86D3C3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    IconButton(icon: Icon(Icons.arrow_back, color: Colors.grey[700]), onPressed: () => Navigator.pop(context)),
                    Expanded(child: Text('Simulasi Praktik\nWudhu & Shalat (FSM)', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.grey[800], height: 1.3))),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.favorite, size: 28, color: i < _nyawa ? Colors.red[500] : Colors.grey[300]),
                  )),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(height: 60, decoration: BoxDecoration(color: const Color(0xFFB8E6D6).withOpacity(0.6), borderRadius: const BorderRadius.vertical(top: Radius.circular(200)))),
                    Image.asset('assets/images/avatar_zaid.jpeg', height: 100, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 100, color: Colors.grey)),
                    Container(
                      width: 180,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [const Color(0xFF6CC458), const Color(0xFF4A9E38)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                        borderRadius: BorderRadius.circular(100),
                        border: const Border(bottom: BorderSide(color: Color(0xFF3B822C), width: 4)),
                        boxShadow: [BoxShadow(color: const Color(0xFF106E5C).withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 10))],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.teal[100]!), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)]),
                      child: Text('Langkah ${_selectedIndex + 1}: ${steps[_selectedIndex].label.replaceAll('\n', ' ')}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.grey[800])),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _StepCard(step: steps[0], selected: _selectedIndex == 0, onTap: () => _onStepTap(0))),
                        const SizedBox(width: 12),
                        Expanded(child: _StepCard(step: steps[1], selected: _selectedIndex == 1, onTap: () => _onStepTap(1))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _StepCard(step: steps[2], selected: _selectedIndex == 2, onTap: () => _onStepTap(2))),
                        const SizedBox(width: 12),
                        Expanded(child: _StepCard(step: steps[3], selected: _selectedIndex == 3, onTap: () => _onStepTap(3))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final _WudhuStep step;
  final bool selected;
  final VoidCallback onTap;
  const _StepCard({required this.step, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? Colors.teal[500]! : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(step.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.water_drop, color: Colors.teal, size: 32))),
                ),
                if (selected)
                  Positioned(
                    top: -8,
                    right: -8,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(color: Colors.teal[500], shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                      child: const Icon(Icons.check, size: 14, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(step.label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: selected ? Colors.teal[900] : Colors.grey[800], height: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _WudhuStep {
  final String id;
  final String label;
  final String imageUrl;
  const _WudhuStep(this.id, this.label, this.imageUrl);
}