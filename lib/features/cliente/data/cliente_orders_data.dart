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
      question: '¿Qué métodos de pago aceptan?',
      answer:
          'Aceptamos transferencia bancaria, PSE y pago en efectivo contra entrega según acuerdo comercial.',
    ),
    FaqItem(
      question: '¿Cómo actualizo mis datos de contacto?',
      answer:
          "Ve a tu perfil (ícono de persona en el menú inferior) y toca 'Editar perfil'.",
    ),
  ];
}