import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/avatar_widget.dart';
import '../../data/models/usuario_model.dart';
import '../../data/repositories/usuario_repository.dart';
import 'edit_user_sheet.dart';

class UserActionSheet extends StatelessWidget {
  final Usuario usuario;
  final VoidCallback onChanged;

  const UserActionSheet({super.key, required this.usuario, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final repo = UsuarioRepository();
    final av = AppColors.avatarPalette[usuario.idUsuario % AppColors.avatarPalette.length];

    Future<void> eliminar() async {
      // ✅ FIX: mostramos el diálogo de confirmación ANTES de cerrar el
      // sheet (se apila encima, usando el context mientras sigue montado).
      // Antes se hacía Navigator.pop(context) primero y luego se usaba
      // ese mismo context (ya inválido) para showDialog, lo que hacía
      // que el diálogo nunca apareciera.
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Eliminar usuario'),
          content: Text(
              '¿Seguro que deseas eliminar a ${usuario.nombreCompleto}? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar', style: TextStyle(color: AppColors.errorText))),
          ],
        ),
      );

      if (!context.mounted) return;

      // Ahora sí cerramos el action sheet, ya con la decisión tomada.
      Navigator.pop(context);

      if (confirm == true) {
        try {
          await repo.eliminarUsuario(usuario.idUsuario);
          onChanged();
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
          }
        }
      }
    }

    void editar() {
      Navigator.pop(context);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => EditUserSheet(usuario: usuario, onChanged: onChanged),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration:
              BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(4)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  AvatarWidget(
                      initials: usuario.initials, size: 40, bg: av['bg']!, text: av['text']!),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(usuario.nombreCompleto,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        Text(usuario.correo ?? '',
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.cardBorder),
            // "Ver perfil" eliminado.
            _ActionTile(
              icon: Icons.edit_outlined,
              label: 'Editar usuario',
              color: AppColors.navy,
              onTap: editar,
            ),
            _ActionTile(
              icon: Icons.delete_outline,
              label: 'Eliminar',
              color: AppColors.errorText,
              onTap: eliminar,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.searchBg,
                    side: const BorderSide(color: AppColors.cardBorder),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Cancelar',
                      style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration:
              BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: color)),
          ],
        ),
      ),
    );
  }
}