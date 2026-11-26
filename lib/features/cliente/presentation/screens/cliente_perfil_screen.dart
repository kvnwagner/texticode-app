import '../../../auth/presentation/screens/perfil_personal_screen.dart';

class ClientePerfilScreen extends PerfilPersonalScreen {
  const ClientePerfilScreen({super.key, required super.onLogout})
      : super(rol: 'Cliente');
}
