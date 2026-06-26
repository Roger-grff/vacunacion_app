import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../providers/auth_provider.dart';
import '../../providers/vaccination_provider.dart';
import '../../models/vaccination_model.dart';
import 'map_picker_view.dart';

class RegisterVaccinationView extends StatefulWidget {
  final VaccinationModel? vaccinationToEdit;

  const RegisterVaccinationView({super.key, this.vaccinationToEdit});

  @override
  State<RegisterVaccinationView> createState() => _RegisterVaccinationViewState();
}

class _RegisterVaccinationViewState extends State<RegisterVaccinationView> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de Texto
  final _ownerNameCtrl = TextEditingController();
  final _ownerCedulaCtrl = TextEditingController();
  final _ownerPhoneCtrl = TextEditingController();
  final _petNameCtrl = TextEditingController();
  final _petAgeCtrl = TextEditingController();
  final _vaccineCtrl = TextEditingController();
  final _observationsCtrl = TextEditingController();

  // Estados del Formulario
  String _petType = 'perro';
  String _petSex = 'Macho';
  File? _selectedImageFile;
  LatLng? _selectedLocation;
  String? _existingPhotoUrl;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.vaccinationToEdit != null) {
      final v = widget.vaccinationToEdit!;
      _ownerNameCtrl.text = v.propietarioNombre;
      _ownerCedulaCtrl.text = v.propietarioCedula;
      _ownerPhoneCtrl.text = v.propietarioTelefono;
      _petNameCtrl.text = v.mascotaNombre;
      _petAgeCtrl.text = v.mascotaEdad.toString();
      _vaccineCtrl.text = v.vacunaAplicada;
      _observationsCtrl.text = v.observaciones;
      _petType = v.mascotaTipo;
      _petSex = v.mascotaSexo;
      _selectedLocation = LatLng(v.latitud, v.longitud);
      _existingPhotoUrl = v.fotoUrl;
    }
  }

  @override
  void dispose() {
    _ownerNameCtrl.dispose();
    _ownerCedulaCtrl.dispose();
    _ownerPhoneCtrl.dispose();
    _petNameCtrl.dispose();
    _petAgeCtrl.dispose();
    _vaccineCtrl.dispose();
    _observationsCtrl.dispose();
    super.dispose();
  }

  // Capturar foto usando la cámara
  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Reducir calidad para optimizar carga y almacenamiento
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
        });
      }
    } catch (e) {
      print('Error al abrir la cámara: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo acceder a la cámara')),
      );
    }
  }

  // Abrir selector de mapa
  Future<void> _pickLocation() async {
    final LatLng? result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MapPickerView(initialPosition: _selectedLocation),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
    }
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedImageFile == null && _existingPhotoUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La foto de la mascota es obligatoria.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona la ubicación en el mapa.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final vacProvider = Provider.of<VaccinationProvider>(context, listen: false);
    final user = authProvider.userModel;

    if (user == null) return;

    final success = await vacProvider.registerVaccination(
      propietarioNombre: _ownerNameCtrl.text.trim(),
      propietarioCedula: _ownerCedulaCtrl.text.trim(),
      propietarioTelefono: _ownerPhoneCtrl.text.trim(),
      mascotaTipo: _petType,
      mascotaNombre: _petNameCtrl.text.trim(),
      mascotaEdad: int.parse(_petAgeCtrl.text.trim()),
      mascotaSexo: _petSex,
      vacunaAplicada: _vaccineCtrl.text.trim(),
      observaciones: _observationsCtrl.text.trim(),
      localPhotoPath: _selectedImageFile != null ? _selectedImageFile!.path : _existingPhotoUrl!,
      latitud: _selectedLocation!.latitude,
      longitud: _selectedLocation!.longitude,
      vacunadorId: widget.vaccinationToEdit?.vacunadorId ?? user.uid,
      sectorId: widget.vaccinationToEdit?.sectorId ?? user.sectorId ?? '',
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registro guardado exitosamente.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Regresar
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar el registro.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vacProvider = Provider.of<VaccinationProvider>(context);
    final isEditing = widget.vaccinationToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Registro' : 'Registrar Vacunación'),
        backgroundColor: const Color(0xFF203A43),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sección de Foto (Obligatoria)
              GestureDetector(
                onTap: _takePhoto,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                  ),
                  child: _selectedImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_selectedImageFile!, fit: BoxFit.cover, width: double.infinity),
                        )
                      : (_existingPhotoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: _existingPhotoUrl!.startsWith('http')
                                  ? Image.network(_existingPhotoUrl!, fit: BoxFit.cover, width: double.infinity)
                                  : Image.file(File(_existingPhotoUrl!), fit: BoxFit.cover, width: double.infinity),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, size: 48, color: Color(0xFF203A43)),
                                SizedBox(height: 8),
                                Text(
                                  'Tomar Foto Mascota (Obligatorio)',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF203A43)),
                                ),
                              ],
                            )),
                ),
              ),
              const SizedBox(height: 24),

              // Propietario Card
              _buildSectionCard(
                title: 'Datos del Propietario',
                children: [
                  TextFormField(
                    controller: _ownerNameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre Completo'),
                    validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ownerCedulaCtrl,
                    decoration: const InputDecoration(labelText: 'Cédula / Identificación'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _ownerPhoneCtrl,
                    decoration: const InputDecoration(labelText: 'Número de Teléfono'),
                    keyboardType: TextInputType.phone,
                    validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mascota Card
              _buildSectionCard(
                title: 'Datos de la Mascota',
                children: [
                  Row(
                    children: [
                      const Text('Tipo:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      ChoiceChip(
                        label: const Text('Perro'),
                        selected: _petType == 'perro',
                        onSelected: (selected) {
                          if (selected) setState(() => _petType = 'perro');
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Gato'),
                        selected: _petType == 'gato',
                        onSelected: (selected) {
                          if (selected) setState(() => _petType = 'gato');
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _petNameCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre de la Mascota'),
                    validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _petAgeCtrl,
                    decoration: const InputDecoration(labelText: 'Edad (Años)'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v!.isEmpty) return 'Campo obligatorio';
                      if (int.tryParse(v) == null) return 'Ingresa un número válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _petSex,
                    decoration: const InputDecoration(labelText: 'Sexo'),
                    items: const [
                      DropdownMenuItem(value: 'Macho', child: Text('Macho')),
                      DropdownMenuItem(value: 'Hembra', child: Text('Hembra')),
                    ],
                    onChanged: (v) => setState(() => _petSex = v!),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Vacuna & Ubicación Card
              _buildSectionCard(
                title: 'Vacunación y Ubicación',
                children: [
                  TextFormField(
                    controller: _vaccineCtrl,
                    decoration: const InputDecoration(labelText: 'Vacuna Aplicada'),
                    validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _observationsCtrl,
                    decoration: const InputDecoration(labelText: 'Observaciones'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  
                  // Botón de Ubicación GPS
                  ElevatedButton.icon(
                    onPressed: _pickLocation,
                    icon: const Icon(Icons.map_outlined),
                    label: Text(
                      _selectedLocation == null
                          ? 'Seleccionar Ubicación GPS'
                          : 'Ubicación: ${_selectedLocation!.latitude.toStringAsFixed(5)}, ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedLocation == null ? Colors.red[50] : Colors.green[50],
                      foregroundColor: _selectedLocation == null ? Colors.red : Colors.green,
                      elevation: 0,
                      side: BorderSide(color: _selectedLocation == null ? Colors.red : Colors.green),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Botón de Guardado
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: vacProvider.isLoading ? null : _saveForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF203A43),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: vacProvider.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          isEditing ? 'Guardar Cambios' : 'Registrar Vacunación',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF203A43)),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}
