import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../models/family.dart';
import '../repositories/family_repository.dart';
import 'family_detail_dialog.dart';
import 'create_family_dialog.dart';
import '../../finances/screens/record_payment_dialog.dart';
import '../../superadmin/repositories/school_repository.dart';
import '../../schools/screens/school_payment_method_screen.dart';

/// Pantalla del Directorio de Cuentas Familiares en EDUNEX
class FamilyDirectoryScreen extends StatefulWidget {
  final FamilyRepository repository;
  final String? colegioId;
  final bool canCreateFamily;

  const FamilyDirectoryScreen({
    super.key,
    required this.repository,
    this.colegioId,
    this.canCreateFamily = true,
  });

  @override
  State<FamilyDirectoryScreen> createState() => _FamilyDirectoryScreenState();
}

class _FamilyDirectoryScreenState extends State<FamilyDirectoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Family> _families = [];
  bool _isLoading = true;
  bool _onlyWithDebt = false;

  @override
  void initState() {
    super.initState();
    _loadFamilies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilies() async {
    setState(() => _isLoading = true);
    try {
      final list = await widget.repository.getFamilies(
        searchQuery: _searchController.text,
        onlyWithDebt: _onlyWithDebt,
        colegioId: widget.colegioId,
      );
      if (mounted) {
        setState(() {
          _families = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openCreateFamilyDialog() async {
    String? targetColegioId = widget.colegioId;
    if (targetColegioId == null || targetColegioId.isEmpty) {
      final schools = await SchoolRepository().getSchools();
      if (schools.isNotEmpty) {
        targetColegioId = schools.first.id;
      }
    }
    if (!mounted) return;
    if (targetColegioId == null || targetColegioId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay centros educativos registrados en el sistema. Registra un colegio primero.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final school = await SchoolRepository().getSchoolById(targetColegioId);
      if (school != null && !school.tieneMetodoPagoValido) {
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.lock_clock_rounded, color: Color(0xFFDC2626), size: 24),
                SizedBox(width: 10),
                Text('Método de Pago Requerido', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Para habilitar el enrolamiento de alumnos y familias en tu centro educativo, debes registrar un método de pago en el menú lateral (Método de Pago & Suscripción).',
              style: TextStyle(fontSize: 13),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cerrar'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(
                          title: const Text('Método de Pago & Suscripción'),
                          backgroundColor: AppColors.navyPrimary,
                          foregroundColor: Colors.white,
                        ),
                        body: SchoolPaymentMethodScreen(
                          colegioId: targetColegioId,
                        ),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.credit_card_rounded, size: 16),
                label: const Text('Configurar Método de Pago'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navyPrimary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
        return;
      }
    } catch (_) {}

    CreateFamilyDialog.show(
      context,
      repository: widget.repository,
      colegioId: targetColegioId,
      onFamilyCreated: (_) => _loadFamilies(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera de la sección
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Directorio de Cuentas Familiares',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navyPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Centralización de hermanos, tutores legales y balances consolidados de colegiatura',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.canCreateFamily)
                  ElevatedButton.icon(
                    onPressed: _openCreateFamilyDialog,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Nueva Familia'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: AppColors.surfaceWhite,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // Barra de Búsqueda y Filtros
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _loadFamilies(),
                      decoration: InputDecoration(
                        hintText: 'Buscar por apellido familiar, código (FAM-...), tutor o estudiante...',
                        hintStyle: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.navyPrimary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _loadFamilies();
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.electricBlue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilterChip(
                    label: const Text('Todas'),
                    selected: !_onlyWithDebt,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _onlyWithDebt = false);
                        _loadFamilies();
                      }
                    },
                    selectedColor: AppColors.navyPrimary.withValues(alpha: 0.12),
                    checkmarkColor: AppColors.navyPrimary,
                    labelStyle: TextStyle(
                      fontWeight: !_onlyWithDebt ? FontWeight.bold : FontWeight.normal,
                      color: !_onlyWithDebt ? AppColors.navyPrimary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Con Deuda Pendiente'),
                    selected: _onlyWithDebt,
                    onSelected: (selected) {
                      setState(() => _onlyWithDebt = selected);
                      _loadFamilies();
                    },
                    selectedColor: const Color(0xFFFEF3C7),
                    checkmarkColor: const Color(0xFFB45309),
                    labelStyle: TextStyle(
                      fontWeight: _onlyWithDebt ? FontWeight.bold : FontWeight.normal,
                      color: _onlyWithDebt ? const Color(0xFFB45309) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Lista o Grid de Familias
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.navyPrimary),
                    )
                  : _families.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                size: 64,
                                color: AppColors.textSecondary.withValues(alpha: 0.4),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No se encontraron cuentas familiares',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Prueba modificando los términos de búsqueda o filtros.',
                                style: TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _families.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final family = _families[index];
                            return _buildFamilyCard(family);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyCard(Family family) {
    final tutorPrincipal = family.tutorPrincipal;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => FamilyDetailDialog.show(context, family, repository: widget.repository).then((_) => _loadFamilies()),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icono / Identificador familiar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.navyPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    color: AppColors.navyPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Información Principal de la Familia
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              family.codigoFamilia,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navyPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              family.nombreFamilia,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Contacto: ${tutorPrincipal != null ? "${tutorPrincipal.nombreCompleto} (${tutorPrincipal.parentesco})" : "Sin tutor principal"} • Tel: ${family.telefonoPrincipal ?? "N/D"}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Hermanos / Estudiantes Matriculados
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      const Icon(Icons.school_outlined, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${family.estudiantes.length} ${family.estudiantes.length == 1 ? "Hijo" : "Hijos"}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              family.estudiantes.map((e) => e.nombres.split(' ').first).join(', '),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Balance y Estado Financiero Consolidado
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: family.estaAlDia
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        family.estaAlDia ? 'AL DÍA' : 'PENDIENTE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: family.estaAlDia
                              ? const Color(0xFF166534)
                              : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      family.estaAlDia
                          ? 'RD\$ 0.00'
                          : 'RD\$ ${family.balancePendiente.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: family.estaAlDia
                            ? const Color(0xFF15803D)
                            : const Color(0xFFB45309),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 8),
                OutlinedButton.icon(
                  key: Key('btn_ver_expediente_${family.id}'),
                  onPressed: () async {
                    await FamilyDetailDialog.show(
                      context,
                      family,
                      repository: widget.repository,
                    );
                    _loadFamilies();
                  },
                  icon: const Icon(Icons.folder_shared_rounded, size: 14),
                  label: const Text('Expediente & Tutores', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navyPrimary,
                    side: const BorderSide(color: AppColors.navyPrimary),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    RecordPaymentDialog.show(
                      context,
                      repository: widget.repository,
                      initialFamily: family,
                      onPaymentRecorded: () => _loadFamilies(),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_rounded, size: 14),
                  label: const Text('Cobrar', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    visualDensity: VisualDensity.compact,
                  ),
                ),

                const SizedBox(width: 12),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
