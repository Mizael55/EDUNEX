import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../models/school.dart';
import '../models/system_announcement.dart';
import '../repositories/school_repository.dart';

/// Modal para publicar y gestionar anuncios y banners globales del sistema EDUNEX
class SystemAnnouncementDialog extends StatefulWidget {
  const SystemAnnouncementDialog({super.key});

  @override
  State<SystemAnnouncementDialog> createState() => _SystemAnnouncementDialogState();
}

class _SystemAnnouncementDialogState extends State<SystemAnnouncementDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SchoolRepository _repository = SchoolRepository();

  List<SystemAnnouncement> _announcements = [];
  List<School> _schools = [];
  bool _isLoading = true;

  // Formulario nuevo anuncio
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _mensajeController = TextEditingController();
  AnnouncementType _selectedTipo = AnnouncementType.info;
  String? _selectedSchoolId; // null = Global para todos
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final schools = await _repository.getSchools();
    final announcements = await _repository.getSystemAnnouncements(onlyActive: false);

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
      final ann = await _repository.createSystemAnnouncement(
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
    await _repository.toggleAnnouncementStatus(ann.id, val);
    if (mounted) {
      AppToast.info(
        context,
        val ? 'Anuncio activado en la red' : 'Anuncio pausado',
      );
      _loadData();
    }
  }

  Future<void> _deleteAnnouncement(SystemAnnouncement ann) async {
    await _repository.deleteSystemAnnouncement(ann.id);
    if (mounted) {
      AppToast.success(
        context,
        'Anuncio eliminado correctamente',
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 850,
        height: 600,
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.electricBlue))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAnnouncementsListTab(),
                        _buildCreateAnnouncementTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.amberAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.campaign, color: AppColors.amberAccent, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anuncios y Banners Globales del Sistema',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Comunicaciones oficiales visibles como banner superior en los portales de los colegios',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.electricBlue,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.electricBlue,
        tabs: [
          Tab(
            icon: const Icon(Icons.list_alt, size: 18),
            text: 'Historial de Anuncios (${_announcements.length})',
          ),
          const Tab(
            icon: Icon(Icons.add_alert, size: 18),
            text: 'Nuevo Anuncio / Aviso',
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsListTab() {
    if (_announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign_outlined, size: 64, color: AppColors.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text(
              'No hay anuncios publicados',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cree un anuncio nuevo para notificar a los colegios sobre mantenimientos o actualizaciones.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _announcements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final ann = _announcements[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: ann.activo ? ann.color.withValues(alpha: 0.4) : AppColors.borderSubtle,
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(ann.icon, color: ann.color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          ann.titulo,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ann.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ann.tipo.displayName,
                            style: TextStyle(
                              color: ann.color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (ann.colegioDestinoId == null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.electricBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Global (Toda la Red)',
                              style: TextStyle(
                                color: AppColors.electricBlue,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ann.mensaje,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Emitido el ${ann.fecha.day}/${ann.fecha.month}/${ann.fecha.year} por ${ann.creadoPor}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
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
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Redactar Nuevo Anuncio',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'El mensaje aparecerá fijado en la parte superior del portal para directores y administradores.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Título
          const Text('Título del Aviso', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _tituloController,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ej: Mantenimiento Preventivo de Base de Datos',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.backgroundSecondary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
            ),
          ),
          const SizedBox(height: 16),

          // Fila Tipo y Destinatario
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Categoría del Aviso', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<AnnouncementType>(
                      value: _selectedTipo,
                      dropdownColor: AppColors.cardBackground,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.backgroundSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
                      ),
                      items: AnnouncementType.values.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(t.displayName),
                        );
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
                    const Text('Destinatario / Alcance', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String?>(
                      value: _selectedSchoolId,
                      dropdownColor: AppColors.cardBackground,
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.backgroundSecondary,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Toda la Red EDUNEX (Global)'),
                        ),
                        ..._schools.map((s) {
                          return DropdownMenuItem<String?>(
                            value: s.id,
                            child: Text(s.nombre),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() => _selectedSchoolId = val);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mensaje
          const Text('Contenido del Mensaje', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _mensajeController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Detalle el motivo, horario o características del anuncio...',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.backgroundSecondary,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderSubtle)),
            ),
          ),
          const SizedBox(height: 24),

          // Botón publicar
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _isPublishing ? null : _publishAnnouncement,
              icon: _isPublishing
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.campaign),
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