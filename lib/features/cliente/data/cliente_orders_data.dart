/// Solo quedan las FAQ de soporte (esas sí son estáticas a propósito).
/// Los pedidos reales ahora vienen de OrdenRepository — ver cliente_home_screen.dart.
class FaqItem {
  final String question;
  final String answer;
  const FaqItem({required this.question, required this.answer});
}

class ClienteOrdersData {
  ClienteOrdersData._();

  static const List<FaqItem> faq = [
    FaqItem(
      question: '¿Cómo hago seguimiento a mi pedido?',
      answer:
          "Accede a la sección 'Mis Pedidos' desde el menú inferior. Ahí verás el estado y porcentaje de avance de cada orden.",
    ),
    FaqItem(
      question: '¿Cuánto tarda en procesarse mi pedido?',
      answer:
          'El tiempo varía según el volumen y tipo de prenda. Recibirás notificaciones en cada cambio de estado.',
    ),
    FaqItem(
      question: '¿Puedo cancelar o modificar un pedido?',
      answer:
          "Sí, mientras el pedido esté en estado 'Pendiente'. Una vez iniciada la producción, contacta a soporte.",
    ),
    FaqItem(
      question: '¿Puedo descargar el comprobante de mi pedido?',
      answer:
          "Sí. Una vez tu pedido aparezca como 'Completada', entra a 'Mis Pedidos', tócalo para expandirlo y usa el botón 'Descargar PDF'. Mientras el pedido no esté completado, ese botón permanece bloqueado.",
    ),
    FaqItem(
      question: '¿Cómo actualizo mis datos de contacto?',
      answer:
          "Ve a tu perfil (ícono de persona en el menú inferior) y toca 'Editar perfil'.",
    ),
  ];
}