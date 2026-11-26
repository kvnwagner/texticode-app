import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Mapea GET /api/eficiencia/operarios y /operarios/:id
/// (eficiencia.js del backend).

Color eficienciaRendimientoColor(String rendimiento) {
  switch (rendimiento) {
    case 'Alto':
      return AppColors.iconActive;
    case 'Medio':
      return AppColors.iconOp;
    default:
      return AppColors.errorText;
  }
}

Color eficienciaRendimientoBg(String rendimiento) {
  switch (rendimiento) {
    case 'Alto':
      return AppColors.badgeOpGreenBg;
    case 'Medio':
      return AppColors.badgeOpBlueBg;
    default:
      return AppColors.errorBg;
  }
}

class ObservacionOperario {
  final int idObservacion;
  final String observacion;
  final String? fecha;
  final String admin;

  ObservacionOperario({
    required this.idObservacion,
    required this.observacion,
    this.fecha,
    required this.admin,
  });

  factory ObservacionOperario.fromJson(Map<String, dynamic> json) {
    return ObservacionOperario(
      idObservacion: _asInt(json['Id_Observacion']),
      observacion: json['Observacion'] ?? '',
      fecha: json['Fecha'],
      admin: json['Admin'] ?? '',
    );
  }

  /// Formatea Fecha (ISO) a "d de mes de yyyy, HH:mm"
  String get fechaCorta {
    if (fecha == null || fecha!.isEmpty) return '';
    try {
      final d = DateTime.parse(fecha!).toLocal();
      final hh = d.hour.toString().padLeft(2, '0');
      final mm = d.minute.toString().padLeft(2, '0');
      return '${d.day}/${d.month}/${d.year}, $hh:$mm';
    } catch (_) {
      return fecha!;
    }
  }
}

class OrdenEficienciaDetalle {
  final int idOrden;
  final String producto;
  final String estado;
  final String? prioridad;
  final String? dificultad;
  final int unidadesRealizadas;
  final int unidades;
  final String? fechaLimite;
  final bool vencida;
  final bool tieneProblema;
  final List<ObservacionOperario> observaciones;

  OrdenEficienciaDetalle({
    required this.idOrden,
    required this.producto,
    required this.estado,
    this.prioridad,
    this.dificultad,
    required this.unidadesRealizadas,
    required this.unidades,
    this.fechaLimite,
    required this.vencida,
    required this.tieneProblema,
    this.observaciones = const [],
  });

  double get avance =>
      unidades == 0 ? 0 : (unidadesRealizadas / unidades).clamp(0, 1).toDouble();

  /// Formatea Fecha_Limite (ISO) a "d/m/yyyy"
  String get fechaLimiteCorta {
    if (fechaLimite == null || fechaLimite!.isEmpty) return '';
    try {
      final d = DateTime.parse(fechaLimite!);
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return fechaLimite!;
    }
  }

  factory OrdenEficienciaDetalle.fromJson(Map<String, dynamic> json) {
    return OrdenEficienciaDetalle(
      idOrden: _asInt(json['Id_Orden']),
      producto: json['Producto'] ?? '',
      estado: json['Estado'] ?? '',
      prioridad: json['Prioridad'],
      dificultad: json['Dificultad'],
      unidadesRealizadas: _asInt(json['Unidades_Realizadas']),
      unidades: _asInt(json['Unidades']),
      fechaLimite: json['Fecha_Limite'],
      vencida: json['vencida'] == true,
      tieneProblema: json['tiene_problema'] == true,
      observaciones: (json['observaciones'] as List?)
              ?.map((e) => ObservacionOperario.fromJson(e))
              .toList() ??
          const [],
    );
  }
}

class EficienciaOperario {
  final int idUsuario;
  final String nombreCompleto;
  final String nombreUsuario;
  final String? correo;
  final String? telefono;
  final double prendasPorDia;
  final int totalUnidadesProducidas;
  final int ordenesEnRetraso;
  final int ordenesCompletadas;
  final int ordenesEnProceso;
  final int ordenesPausadas;
  final int ordenesConProblema;
  final String rendimiento; // Alto | Medio | Bajo (viene calculado del backend)
  final List<OrdenEficienciaDetalle>? ordenesDetalle;

  EficienciaOperario({
    required this.idUsuario,
    required this.nombreCompleto,
    required this.nombreUsuario,
    this.correo,
    this.telefono,
    required this.prendasPorDia,
    required this.totalUnidadesProducidas,
    required this.ordenesEnRetraso,
    required this.ordenesCompletadas,
    required this.ordenesEnProceso,
    required this.ordenesPausadas,
    required this.ordenesConProblema,
    required this.rendimiento,
    this.ordenesDetalle,
  });

  String get initials {
    final parts = nombreCompleto.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '??';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  factory EficienciaOperario.fromJson(Map<String, dynamic> json) {
    return EficienciaOperario(
      idUsuario: _asInt(json['Id_Usuario']),
      nombreCompleto: json['Nombre_Completo'] ?? '',
      nombreUsuario: json['Nombre_Usuario'] ?? '',
      correo: json['Correo'],
      telefono: json['Telefono'],
      prendasPorDia: _asDouble(json['prendas_por_dia']),
      totalUnidadesProducidas: _asInt(json['total_unidades_producidas']),
      ordenesEnRetraso: _asInt(json['ordenes_en_retraso']),
      ordenesCompletadas: _asInt(json['ordenes_completadas']),
      ordenesEnProceso: _asInt(json['ordenes_en_proceso']),
      ordenesPausadas: _asInt(json['ordenes_pausadas']),
      ordenesConProblema: _asInt(json['ordenes_con_problema']),
      rendimiento: json['rendimiento'] ?? 'Bajo',
      ordenesDetalle: (json['ordenes_detalle'] as List?)
          ?.map((e) => OrdenEficienciaDetalle.fromJson(e))
          .toList(),
    );
  }
}

/// Mapea GET /api/eficiencia/operarios/:id/historial?periodo=
class EficienciaHistorialPeriodo {
  final double prendasPorDia;
  final int totalUnidades;
  final int completadas;
  final int enCurso;
  final int retrasos;
  final int conProblema;
  final String rendimiento;

  EficienciaHistorialPeriodo({
    required this.prendasPorDia,
    required this.totalUnidades,
    required this.completadas,
    required this.enCurso,
    required this.retrasos,
    required this.conProblema,
    required this.rendimiento,
  });

  factory EficienciaHistorialPeriodo.fromJson(Map<String, dynamic> json) {
    return EficienciaHistorialPeriodo(
      prendasPorDia: _asDouble(json['prendas_por_dia']),
      totalUnidades: _asInt(json['total_unidades']),
      completadas: _asInt(json['completadas']),
      enCurso: _asInt(json['en_curso']),
      retrasos: _asInt(json['retrasos']),
      conProblema: _asInt(json['con_problema']),
      rendimiento: json['rendimiento'] ?? 'Bajo',
    );
  }
}

class EficienciaHistorial {
  final String periodo; // semana | mes | trimestre
  final int dias;
  final EficienciaHistorialPeriodo actual;
  final EficienciaHistorialPeriodo anterior;
  final String tendencia; // subiendo | bajando | estable
  final double diferenciaPrendas;

  EficienciaHistorial({
    required this.periodo,
    required this.dias,
    required this.actual,
    required this.anterior,
    required this.tendencia,
    required this.diferenciaPrendas,
  });

  factory EficienciaHistorial.fromJson(Map<String, dynamic> json) {
    return EficienciaHistorial(
      periodo: json['periodo'] ?? 'semana',
      dias: _asInt(json['dias']),
      actual: EficienciaHistorialPeriodo.fromJson(json['actual'] ?? {}),
      anterior: EficienciaHistorialPeriodo.fromJson(json['anterior'] ?? {}),
      tendencia: json['tendencia'] ?? 'estable',
      diferenciaPrendas: _asDouble(json['diferencia_prendas']),
    );
  }
}

int _asInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is double) return v.round();
  return int.tryParse('$v') ?? 0;
}

double _asDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}