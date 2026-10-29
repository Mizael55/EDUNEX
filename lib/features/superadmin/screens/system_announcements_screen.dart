import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../models/school.dart';
import '../models/system_announcement.dart';
import '../repositories/school_repository.dart';

/// Pantalla completa de Anuncios y Banners del Sistema para el Menú Lateral
class SystemAnnouncementsScreen extends StatefulWidget {
  final SchoolRepository schoolRepository;

  const SystemAnnouncementsScreen({super.key, required this.schoolRepository});

  @override
  State<SystemAnnouncementsScreen> createState() => _SystemAnnouncementsScreenState();
}

class _SystemAnnouncementsScreenState extends State<SystemAnnouncementsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<SystemAnnouncement> _announcements = [];
  List<School> _schools = [];
  bool _isLoading = true;

  // Formulario nuevo anuncio
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _mensajeController = TextEditingController();
  AnnouncementType _selectedTipo = AnnouncementType.info;
  String? _selectedSchoolId; // null = Global
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final schools = await widget.schoolRepository.getSchools();
    final announcements = await widget.schoolRepository.getSystemAnnouncements(onlyActive: false);

    if (mounted) {
      setState(() {
        _schools = schools;
        _announcements = announcements;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tituloController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _publishAnnouncement() async {
    if (_tituloController.text.trim().isEmpty) {
      AppToast.warning(context, 'Ingrese un título para el anuncio');
      return;
    }
    if (_mensajeController.text.trim().isEmpty) {
      AppToast.warning(context, 'Ingrese el contenido del mensaje');
      return;
    }

    setState(() => _isPublishing = true);
    try {
      final ann = await widget.schoolRepository.createSystemAnnouncement(
        titulo: _tituloController.text.trim(),
        mensaje: _mensajeController.text.trim(),
        tipo: _selectedTipo,
        colegioDestinoId: _selectedSchoolId,
      );

      if (mounted) {
        AppToast.success(
          context,
          'Anuncio global "${ann.titulo}" publicado exitosamente',
        );
        _tituloController.clear();
        _mensajeController.clear();
        _selectedTipo = AnnouncementType.info;
        _selectedSchoolId = null;
        await _loadData();
        _tabController.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error publicando anuncio: $e');
      }
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  Future<void> _toggleStatus(SystemAnnouncement ann, bool val) async {
    await widget.schoolRepository.toggleAnnouncementStatus(ann.id, val);
    if (mounted) {
      AppToast.info(context, val ? 'Anuncio activado en la red' : 'Anuncio pausado');
      _loadData();
    }
  }

  Future<void> _deleteAnnouncement(SystemAnnouncement ann) async {
    await widget.schoolRepository.deleteSystemAnnouncement(ann.id);
    if (mounted) {
      AppToast.success(context, 'Anuncio eliminado correctamente');
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _announcements.where((a) => a.activo).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera Moderna
            _buildTopHeader(activeCount),
            const SizedBox(height: 20),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.amberAccent,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.amberAccent,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.campaign_rounded, size: 18),
                    text: 'Anuncios Activos & Historial (${_announcements.length})',
                  ),
                  const Tab(
                    icon: Icon(Icons.add_alert_rounded, size: 18),
                    text: 'Publicar Nuevo Aviso',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Contenedor principal
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(20),
              child: _isLoading
                  ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                  : SizedBox(
                      height: 520,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildAnnouncementsListTab(),
                          _buildCreateAnnouncementTab(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(int activeCount) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.amberAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'COMUNICACIONES GLOBALES SAAS',
                      style: TextStyle(
                        color: Color(0xFFB45309),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Text('$activeCount anuncios activos actualmente', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Anuncios y Banners del Sistema',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navyPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Emisión de avisos oficiales de mantenimiento, nuevas características o alertas críticas para todos los colegios de la red EDUNEX.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _tabController.animateTo(1),
          icon: const Icon(Icons.campaign_rounded, size: 18),
          label: const Text('+ Crear Nuevo Aviso'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.amberAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsListTab() {
    if (_announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            const Text(
              'No hay anuncios publicados en el sistema',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Utiliza la pestaña "Publicar Nuevo Aviso" para notificar a los colegios.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _announcements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ann = _announcements[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ann.activo ? ann.color.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ann.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(ann.icon, color: ann.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          ann.titulo,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navyPrimary),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ann.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ann.tipo.displayName,
                            style: TextStyle(color: ann.color, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (ann.colegioDestinoId == null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Global (Toda la Red)',
                              style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ann.mensaje,
                      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Emitido el ${ann.fecha.day}/${ann.fecha.month}/${ann.fecha.year} por ${ann.creadoPor}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  Switch(
                    value: ann.activo,
                    activeColor: AppColors.accentGreen,
                    onChanged: (val) => _toggleStatus(ann, val),
                  ),
                  IconButton(
                    onPressed: () => _deleteAnnouncement(ann),
                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
                    tooltip: 'Eliminar Anuncio',
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreateAnnouncementTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Redactar Comunicado Oficial',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'El mensaje aparecerá fijado en la parte superior del portal para directores y administradores.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Título
          const Text('Título del Aviso', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navyPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _tituloController,
            decoration: InputDecoration(
              hintText: 'Ej: Mantenimiento Preventivo de Base de Datos',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 16),

          // Fila Tipo y Alcance
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Categoría del Aviso', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navyPrimary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<AnnouncementType>(
                      value: _selectedTipo,
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      items: AnnouncementType.values.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t.displayName));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedTipo = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Destinatario / Alcance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navyPrimary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: _selectedSchoolId,
                      dropdownColor: Colors.white,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Toda la Red EDUNEX (Global)'),
                        ),
                        ..._schools.map((s) {
                          return DropdownMenuItem<String?>(value: s.id, child: Text(s.nombre));
                        }),
                      ],
                      onChanged: (val) => setState(() => _selectedSchoolId = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mensaje
          const Text('Contenido del Mensaje', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navyPrimary)),
          const SizedBox(height: 8),
          TextField(
            controller: _mensajeController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Detalle el motivo, horario o características del aviso...',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
          const SizedBox(height: 24),

          // Botón publicar
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isPublishing ? null : _publishAnnouncement,
              icon: _isPublishing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.campaign_rounded),
              label: Text(
                _isPublishing ? 'Publicando...' : 'Publicar Anuncio Global',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.amberAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}