import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/comprobante_model.dart';
import '../../data/models/orden_model.dart';
import '../../data/models/usuario_model.dart';
import '../../data/services/pdf_descarga.dart';
import '../../data/services/comprobante_pdf_service.dart';

// ── Vista previa del comprobante (bottom sheet con el PDF) ───────────────

class ComprobantePreviewSheet extends StatelessWidget {
  final Comprobante comprobante;
  final Usuario? cliente;
  final Orden? orden;

  const ComprobantePreviewSheet({
    super.key,
    this.orden,
    required this.comprobante,
    required this.cliente,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Comprobante #${comprobante.numero}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<Uint8List>(
                  future: ComprobantePdfService.generar(
                    comprobante: comprobante,
                    cliente: cliente,
                    orden: orden,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.navy,
                        ),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return Center(
                        child: Text(
                          'No se pudo generar la vista previa.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      );
                    }

                    return PdfPreview(
                      build: (format) async => snapshot.data!,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                      allowSharing: true,
                      pdfFileName: 'comprobante-${comprobante.numero}.pdf',
                      actions: [
                        PdfPreviewAction(
                          icon: const Tooltip(
                            message: 'Descargar PDF',
                            child: Icon(Icons.download_outlined),
                          ),
                          onPressed: (context, _, __) async {
                            try {
                              await PdfDescarga.guardar(
                                snapshot.data!,
                                'comprobante-${comprobante.numero}.pdf',
                              );
                            } catch (_) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No se pudo guardar el PDF.'),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                      allowPrinting: true,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
