import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/autenticacion_proveedor.dart';
import '../../providers/sector_proveedor.dart';
import '../../models/usuario_modelo.dart';
import '../../models/sector_modelo.dart';
import '../../services/firestore_servicio.dart';
import 'detalle_usuario_vista.dart';

class ManageUsersView extends StatefulWidget {
  const ManageUsersView({super.key});

  @override
  State<ManageUsersView> createState() => _ManageUsersViewState();
}

class _ManageUsersViewState extends State<ManageUsersView> {
  final _firestoreService = FirestoreService();
  
  // Controladores de Registro y Búsqueda
  final _cedulaCtrl = TextEditingController();
  final _nombresCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void dispose() {
    _cedulaCtrl.dispose();
    _nombresCtrl.dispose();
    _apellidosCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Diálogo para registrar un nuevo usuario
  void _showCreateUserDialog(UserModel currentUser) {
    _cedulaCtrl.clear();
    _nombresCtrl.clear();
    _apellidosCtrl.clear();
    _phoneCtrl.clear();
    _emailCtrl.clear();

    String selectedRol = currentUser.rol == 'coordinador_campana' 
        ? 'coordinador_brigada' 
        : 'vacunador';
    
    String? selectedSectorId = currentUser.rol == 'coordinador_brigada'
        ? currentUser.sectorId
        : null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setDialogState) {
            final sectorProvider = Provider.of<SectorProvider>(statefulContext);
            
            return AlertDialog(
              title: const Text('Registrar Nuevo Usuario'),
              content: SingleChildScrollView(
                child: Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _cedulaCtrl,
                        decoration: const InputDecoration(labelText: 'Cédula / Identificación'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nombresCtrl,
                        decoration: const InputDecoration(labelText: 'Nombres'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _apellidosCtrl,
                        decoration: const InputDecoration(labelText: 'Apellidos'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Teléfono'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      
                      // Selección de Rol (Solo Coordinador de Campaña)
                      if (currentUser.rol == 'coordinador_campana') ...[
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedRol,
                          decoration: const InputDecoration(labelText: 'Rol'),
                          items: const [
                            DropdownMenuItem(
                              value: 'coordinador_brigada',
                              child: Text('Coordinador de Brigada', overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'vacunador',
                              child: Text('Vacunador', overflow: TextOverflow.ellipsis),
                            ),
                          ],
                          onChanged: (v) {
                            setDialogState(() {
                              selectedRol = v!;
                              if (selectedRol == 'coordinador_brigada') {
                                selectedSectorId = null; // Coordinadores se asignan en vista de sectores
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Selección de Sector (Solo si es vacunador creado por Campaña)
                      if (currentUser.rol == 'coordinador_campana' && selectedRol == 'vacunador') ...[
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedSectorId,
                          decoration: const InputDecoration(labelText: 'Asignar Sector'),
                          items: sectorProvider.sectors.map((sector) {
                            return DropdownMenuItem(
                              value: sector.id,
                              child: Text(sector.nombre, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (v) => setDialogState(() => selectedSectorId = v),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(statefulContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Validar campos básicos
                    if (_cedulaCtrl.text.isEmpty ||
                        _nombresCtrl.text.isEmpty ||
                        _apellidosCtrl.text.isEmpty ||
                        _phoneCtrl.text.isEmpty ||
                        _emailCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(statefulContext).showSnackBar(
                        const SnackBar(content: Text('Por favor completa todos los campos')),
                      );
                      return;
                    }

                    final provider = Provider.of<SectorProvider>(statefulContext, listen: false);
                    final passwordGenerada = await provider.createUser(
                      cedula: _cedulaCtrl.text.trim(),
                      nombres: _nombresCtrl.text.trim(),
                      apellidos: _apellidosCtrl.text.trim(),
                      telefono: _phoneCtrl.text.trim(),
                      correo: _emailCtrl.text.trim(),
                      rol: selectedRol,
                      sectorId: selectedSectorId,
                    );

                    if (mounted) {
                      Navigator.of(statefulContext).pop(); // Cierra el modal de creación
                      if (passwordGenerada != null) {
                        // Mostrar diálogo especial con la contraseña generada VTE...
                        // Usamos el 'context' de la página principal para que persista
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (passwordDialogContext) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Usuario Creado'),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('El usuario ha sido registrado exitosamente con clave temporal.'),
                                const SizedBox(height: 16),
                                const Text('Contraseña Inicial:', style: TextStyle(fontWeight: FontWeight.bold)),
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[400]!),
                                  ),
                                  child: SelectableText(
                                    passwordGenerada,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                      color: Color(0xFF203A43),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Importante: Copia esta contraseña y proporciónasela al usuario. Deberá cambiarla al iniciar sesión por primera vez.',
                                  style: TextStyle(fontSize: 12, color: Colors.red, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(passwordDialogContext).pop(),
                                child: const Text('Entendido'),
                              )
                            ],
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Error al crear el usuario. Verifique el correo.')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF203A43),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Registrar'),
                )
              ],
            );
          },
        );
      },
    );
  }

  // Diálogo para editar los datos de un usuario
  void _showEditUserDialog(UserModel userToEdit, UserModel currentUser) {
    _cedulaCtrl.text = userToEdit.cedula;
    _nombresCtrl.text = userToEdit.nombres;
    _apellidosCtrl.text = userToEdit.apellidos;
    _phoneCtrl.text = userToEdit.telefono;
    _emailCtrl.text = userToEdit.correo;

    String selectedRol = userToEdit.rol;
    String? selectedSectorId = userToEdit.sectorId;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (statefulContext, setDialogState) {
            final sectorProvider = Provider.of<SectorProvider>(statefulContext);
            return AlertDialog(
              title: Text('Editar Usuario: ${userToEdit.nombres}'),
              content: SingleChildScrollView(
                child: Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _cedulaCtrl,
                        decoration: const InputDecoration(labelText: 'Cédula / Identificación'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nombresCtrl,
                        decoration: const InputDecoration(labelText: 'Nombres'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _apellidosCtrl,
                        decoration: const InputDecoration(labelText: 'Apellidos'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Teléfono'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(labelText: 'Correo Electrónico'),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      // Selección de Rol (Solo Coordinador de Campaña y si no es el administrador mismo)
                      if (currentUser.rol == 'coordinador_campana' && userToEdit.rol != 'coordinador_campana') ...[
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedRol,
                          decoration: const InputDecoration(labelText: 'Rol'),
                          items: const [
                            DropdownMenuItem(
                              value: 'coordinador_brigada',
                              child: Text('Coordinador de Brigada', overflow: TextOverflow.ellipsis),
                            ),
                            DropdownMenuItem(
                              value: 'vacunador',
                              child: Text('Vacunador', overflow: TextOverflow.ellipsis),
                            ),
                          ],
                          onChanged: (v) {
                            setDialogState(() {
                              selectedRol = v!;
                              if (selectedRol == 'coordinador_brigada') {
                                selectedSectorId = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Selección de Sector (Solo si es vacunador)
                      if (selectedRol == 'vacunador') ...[
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedSectorId,
                          decoration: const InputDecoration(labelText: 'Asignar Sector'),
                          items: sectorProvider.sectors.map((sector) {
                            return DropdownMenuItem(
                              value: sector.id,
                              child: Text(sector.nombre, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (v) => setDialogState(() => selectedSectorId = v),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(statefulContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_cedulaCtrl.text.isEmpty ||
                        _nombresCtrl.text.isEmpty ||
                        _apellidosCtrl.text.isEmpty ||
                        _phoneCtrl.text.isEmpty ||
                        _emailCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(statefulContext).showSnackBar(
                        const SnackBar(content: Text('Por favor completa todos los campos')),
                      );
                      return;
                    }

                    final updatedUser = UserModel(
                      uid: userToEdit.uid,
                      cedula: _cedulaCtrl.text.trim(),
                      nombres: _nombresCtrl.text.trim(),
                      apellidos: _apellidosCtrl.text.trim(),
                      telefono: _phoneCtrl.text.trim(),
                      correo: _emailCtrl.text.trim(),
                      rol: selectedRol,
                      sectorId: selectedSectorId,
                      cambioPassword: userToEdit.cambioPassword,
                    );

                    final success = await sectorProvider.editUser(updatedUser);

                    if (mounted) {
                      Navigator.of(statefulContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Usuario actualizado con éxito' : 'Error al actualizar usuario'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF203A43),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Diálogo para confirmar la eliminación de un usuario
  void _confirmDeleteUser(UserModel userToDelete) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que deseas eliminar al usuario "${userToDelete.nombreCompleto}"?\n\nEsta acción borrará su perfil de Firestore y revocará su acceso.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final provider = Provider.of<SectorProvider>(context, listen: false);
              final success = await provider.deleteUser(userToDelete.uid);

              if (mounted) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Usuario eliminado con éxito' : 'Error al eliminar usuario'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Diálogo para reasignar sector a vacunadores
  void _showReassignSectorDialog(UserModel user) {
    final sectorProvider = Provider.of<SectorProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reasignar Sector a ${user.nombres}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sectorProvider.sectors.length,
            itemBuilder: (context, index) {
              final sector = sectorProvider.sectors[index];
              final esActual = user.sectorId == sector.id;

              return ListTile(
                title: Text(sector.nombre),
                trailing: esActual ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () async {
                  final success = await sectorProvider.reassignVaccinator(user.uid, sector.id);
                  if (mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(success ? 'Sector reasignado con éxito' : 'Error al reasignar'),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final sectorProvider = Provider.of<SectorProvider>(context);
    final currentUser = authProvider.userModel;

    if (currentUser == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Filtrar los usuarios a listar según el rol actual
    return StreamBuilder<List<UserModel>>(
      stream: currentUser.rol == 'coordinador_campana'
          ? _firestoreService.getUsers() // Coordinador de campaña ve a todos
          : _firestoreService.getUsers(sectorId: currentUser.sectorId, rol: 'vacunador'), // Coordinador de brigada ve vacunadores de su sector
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];

        final filteredUsers = users.where((u) {
          final query = _searchQuery.toLowerCase();
          final fullName = u.nombreCompleto.toLowerCase();
          final email = u.correo.toLowerCase();
          final phone = u.telefono;
          final cedula = u.cedula;
          return fullName.contains(query) || email.contains(query) || phone.contains(query) || cedula.contains(query);
        }).toList();

        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreateUserDialog(currentUser),
            backgroundColor: const Color(0xFF203A43),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add),
            label: const Text('Crear Usuario'),
          ),
          body: Column(
            children: [
              // Barra de Búsqueda
              if (users.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar usuario (nombre, correo, cédula, tel)...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF203A43)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = "";
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: users.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No hay usuarios registrados.',
                              style: TextStyle(color: Colors.grey[500], fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : filteredUsers.isEmpty
                        ? const Center(
                            child: Text(
                              'No se encontraron usuarios con ese criterio.',
                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              
                              // Encontrar nombre del sector del usuario
                              final sectorName = sectorProvider.sectors.firstWhere(
                                (s) => s.id == user.sectorId,
                                orElse: () => SectorModel(id: '', nombre: 'Sin Asignar', parroquia: '', zona: '', activo: false),
                              ).nombre;

                              String formatRole(String rol) {
                                if (rol == 'coordinador_campana') return 'Campaña';
                                if (rol == 'coordinador_brigada') return 'Brigada';
                                return 'Vacunador';
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => DetalleUsuarioVista(user: user),
                                      ),
                                    );
                                  },
                                  title: Text(
                                    user.nombreCompleto.toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Correo: ${user.correo} • Tel: ${user.telefono}'),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Chip(
                                            label: Text(formatRole(user.rol), style: const TextStyle(fontSize: 10)),
                                            padding: EdgeInsets.zero,
                                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Sector: $sectorName',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (currentUser.rol == 'coordinador_campana' ||
                                          (currentUser.rol == 'coordinador_brigada' &&
                                              user.rol == 'vacunador' &&
                                              user.sectorId == currentUser.sectorId)) ...[
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Color(0xFF203A43)),
                                          tooltip: 'Editar Usuario',
                                          onPressed: () => _showEditUserDialog(user, currentUser),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                          tooltip: 'Eliminar Usuario',
                                          onPressed: () => _confirmDeleteUser(user),
                                        ),
                                      ],
                                      if (currentUser.rol == 'coordinador_brigada' && user.rol == 'vacunador')
                                        IconButton(
                                          icon: const Icon(Icons.swap_horiz, color: Color(0xFF203A43)),
                                          tooltip: 'Reasignar / Cambiar Sector',
                                          onPressed: () => _showReassignSectorDialog(user),
                                        ),
                                    ],
                                  ),
                                ),
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

