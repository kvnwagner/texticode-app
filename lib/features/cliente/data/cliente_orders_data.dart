class ClienteOrder {
  final String id;
  final String name;
  final String status; // En progreso | Completado | Pausado
  final int pct;
  final String delivery;
  final String material;

  const ClienteOrder({
    required this.id,
    required this.name,
    required this.status,
    required this.pct,
    required this.delivery,
    required this.material,
  });
}

class FaqItem {
  final String question;
  final String answer;
  const FaqItem({required this.question, required this.answer});
}

class ClienteOrdersData {
  ClienteOrdersData._();

  static const List<ClienteOrder> orders = [
    ClienteOrder(
      id: '#P-089',
      name: 'Camisas Oxford x12',
      status: 'En progreso',
      pct: 65,
      delivery: '02/6/2026',
      material: 'Algodón peinado',
    ),
    ClienteOrder(
      id: '#P-076',
      name: 'Pantalones slim x6',
      status: 'Completado',
      pct: 100,
      delivery: '18/5/2026',
      material: 'Denim 12oz',
    ),
    ClienteOrder(
      id: '#P-063',
      name: 'Vestidos formales x4',
      status: 'Pausado',
      pct: 30,
      delivery: '10/6/2026',
      material: 'Seda natural',
    ),
    ClienteOrder(
      id: '#P-051',
      name: 'Chaquetas cuero x2',
      status: 'Completado',
      pct: 100,
      delivery: '01/5/2026',
      material: 'Cuero sintético',
    ),
  ];

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