import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/cliente_orders_data.dart';
import '../widgets/cliente_shared_widgets.dart';

class ClienteSoporteScreen extends StatefulWidget {
  final VoidCallback onLogout;
  const ClienteSoporteScreen({super.key, required this.onLogout});

  @override
  State<ClienteSoporteScreen> createState() => _ClienteSoporteScreenState();
}

class _ClienteSoporteScreenState extends State<ClienteSoporteScreen> {
  int? _openFaq;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClienteLogoHeader(
          title: 'Centro de Soporte',
          subtitle: 'Estamos aquí para ayudarte',
          onLogout: widget.onLogout,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: ClienteColors.profileGradient,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('¿Necesitas ayuda?',
                                  style: TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                              const SizedBox(height: 2),
                              Text('Contacta a nuestro equipo de soporte',
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6), fontSize: 11)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: AppColors.pageBg,
                          child: const Column(
                            children: [
                              _ContactButton(
                                icon: Icons.call_outlined,
                                label: 'Llamar al soporte',
                                sub: '+57 601 234 5678',
                                color: AppColors.iconActive,
                              ),
                              SizedBox(height: 10),
                              _ContactButton(
                                icon: Icons.chat_bubble_outline,
                                label: 'WhatsApp',
                                sub: '+57 311 987 6543',
                                color: Color(0xFF25D366),
                              ),
                              SizedBox(height: 10),
                              _ContactButton(
                                icon: Icons.mail_outline,
                                label: 'Enviar correo',
                                sub: 'soporte@texticode.com',
                                color: AppColors.iconOp,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.support_agent, size: 16, color: AppColors.navy),
                          SizedBox(width: 8),
                          Text('Horario de atención',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _scheduleRow('Lunes – Viernes', '8:00 AM – 6:00 PM'),
                      _scheduleRow('Sábados', '9:00 AM – 1:00 PM'),
                      _scheduleRow('Domingos', 'No disponible', muted: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClienteSectionHeader(title: 'Preguntas frecuentes', count: ClienteOrdersData.faq.length),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: List.generate(ClienteOrdersData.faq.length, (i) {
                    final item = ClienteOrdersData.faq[i];
                    final isOpen = _openFaq == i;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isOpen
                                ? AppColors.navy.withValues(alpha: 0.4)
                                : AppColors.cardBorder),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setState(() => _openFaq = isOpen ? null : i),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              color: isOpen
                                  ? AppColors.navy.withValues(alpha: 0.05)
                                  : AppColors.pageBg,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(item.question,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary)),
                                  ),
                                  Icon(
                                    isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                    size: 18,
                                    color: isOpen ? AppColors.navy : AppColors.textFaint,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isOpen)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                              color: AppColors.navy.withValues(alpha: 0.03),
                              child: Text(item.answer,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: AppColors.textSecondary)),
                            ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scheduleRow(String day, String hours, {bool muted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(hours,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: muted ? AppColors.textFaint : AppColors.navy)),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.textFaint),
        ],
      ),
    );
  }
}