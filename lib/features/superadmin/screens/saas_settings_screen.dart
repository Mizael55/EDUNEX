import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../core/widgets/app_toast.dart';
import '../models/saas_company_config.dart';
import '../repositories/school_repository.dart';

class SaaSSettingsScreen extends StatefulWidget {
  final SchoolRepository schoolRepository;

  const SaaSSettingsScreen({
    super.key,
    required this.schoolRepository,
  });

  @override
  State<SaaSSettingsScreen> createState() => _SaaSSettingsScreenState();
}

class _SaaSSettingsScreenState extends State<SaaSSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final TextEditingController _rncController = TextEditingController();
  final TextEditingController _razonSocialController = TextEditingController();
  final TextEditingController _nombreComercialController = TextEditingController();
  final TextEditingController _emailFacturacionController = TextEditingController();
  final TextEditingController _emailSoporteController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _sitioWebController = TextEditingController();

  final TextEditingController _ncfB01Controller = TextEditingController();
  final TextEditingController _ncfB02Controller = TextEditingController();
  final TextEditingController _diasGraciaController = TextEditingController();
  final TextEditingController _itbisController = TextEditingController();

  bool _modoMantenimiento = false;
  bool _exigir2FA = false;
  int _minPasswordLength = 8;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadConfig();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rncController.dispose();
    _razonSocialController.dispose();
    _nombreComercialController.dispose();
    _emailFacturacionController.dispose();
    _emailSoporteController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _sitioWebController.dispose();
    _ncfB01Controller.dispose();
    _ncfB02Controller.dispose();
    _diasGraciaController.dispose();
    _itbisController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    try {
      final config = await widget.schoolRepository.getCompanyConfig();
      if (mounted) {
        _rncController.text = config.rnc;
        _razonSocialController.text = config.razonSocial;
        _nombreComercialController.text = config.nombreComercial;
        _emailFacturacionController.text = config.emailFacturacion;
        _emailSoporteController.text = config.emailSoporte;
        _telefonoController.text = config.telefono;
        _direccionController.text = config.direccion;
        _sitioWebController.text = config.sitioWeb;

        _ncfB01Controller.text = '${config.secuenciaNCFB01}';
        _ncfB02Controller.text = '${config.secuenciaNCFB02}';
        _diasGraciaController.text = '${config.diasGraciaSuspension}';
        _itbisController.text = '${(config.tasaItbis * 100).toStringAsFixed(0)}';

        _modoMantenimiento = config.modoMantenimiento;
        _exigir2FA = config.exigir2FA;
        _minPasswordLength = config.minPasswordLength;

        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);

    try {
      final updated = SaaSCompanyConfig(
        rnc: _rncController.text.trim(),
        razonSocial: _razonSocialController.text.trim(),
        nombreComercial: _nombreComercialController.text.trim(),
        emailFacturacion: _emailFacturacionController.text.trim(),
        emailSoporte: _emailSoporteController.text.trim(),
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
        sitioWeb: _sitioWebController.text.trim(),
        secuenciaNCFB01: int.tryParse(_ncfB01Controller.text.trim()) ?? 105,
        secuenciaNCFB02: int.tryParse(_ncfB02Controller.text.trim()) ?? 230,
        diasGraciaSuspension: int.tryParse(_diasGraciaController.text.trim()) ?? 15,
        tasaItbis: (double.tryParse(_itbisController.text.trim()) ?? 18) / 100.0,
        modoMantenimiento: _modoMantenimiento,
        exigir2FA: _exigir2FA,
        minPasswordLength: _minPasswordLength,
      );

      await widget.schoolRepository.saveCompanyConfig(updated);

      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.success(
          context,
          'Parámetros corporativos y fiscales actualizados correctamente.',
          title: 'Configuración Guardada',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppToast.error(
          context,
          'Error guardando configuración: $e',
          title: 'Error de Guardado',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 900;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isCompact),
                const SizedBox(height: 20),
                _buildTabSection(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(bool isCompact) {
    final titleSection = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.navyPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'SISTEMA SAAS',
                style: TextStyle(
                  color: AppColors.navyPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const Text(
              'Parámetros Globales de EDUNEX',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Configuración de la Empresa Matriz SaaS',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Datos fiscales DGII, correlativos de NCF, políticas de suspensión y seguridad de la plataforma.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );

    final actionButton = ElevatedButton.icon(
      onPressed: _isSaving || _isLoading ? null : _saveConfig,
      icon: _isSaving
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.save_rounded, size: 18),
      label: Text(_isSaving ? 'Guardando...' : 'Guardar Configuración'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navyPrimary,
        foregroundColor: AppColors.surfaceWhite,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleSection,
          const SizedBox(height: 14),
          actionButton,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleSection),
        const SizedBox(width: 14),
        actionButton,
      ],
    );
  }

  Widget _buildTabSection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50),
          child: CircularProgressIndicator(color: AppColors.navyPrimary),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.navyPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.navyPrimary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(
                  icon: Icon(Icons.business_rounded, size: 18),
                  text: 'Empresa Matriz & Facturación DGII',
                ),
                Tab(
                  icon: Icon(Icons.security_rounded, size: 18),
                  text: 'Seguridad & Plataforma',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                if (_tabController.index == 0) {
                  return _buildCompanyAndTaxTab();
                } else {
                  return _buildSecurityTab();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyAndTaxTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. Identidad Fiscal de la Empresa Matriz (Emisor SaaS)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Esta información aparecerá en las facturas B01/B02 generadas a los colegios afiliados.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('RNC de la Empresa *', _rncController, 'Ej. 1-32-45678-9', Icons.badge_outlined)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Razón Social *', _razonSocialController, 'Ej. EDUNEX Dominicana SAS', Icons.corporate_fare_rounded)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField('Nombre Comercial', _nombreComercialController, 'EDUNEX - Plataforma SaaS', Icons.domain_rounded)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Sitio Web', _sitioWebController, 'https://edunex.edu.do', Icons.language_rounded)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField('Correo Facturación *', _emailFacturacionController, 'facturacion@edunex.edu.do', Icons.email_outlined)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Correo Soporte', _emailSoporteController, 'soporte@edunex.edu.do', Icons.support_agent_rounded)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField('Teléfono PBX', _telefonoController, '809-555-0199', Icons.phone_outlined)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Dirección Fiscal', _direccionController, 'Torre Empresarial, Sto. Dgo.', Icons.location_on_outlined)),
          ],
        ),
        const SizedBox(height: 28),
        const Divider(color: Color(0xFFE2E8F0)),
        const SizedBox(height: 20),
        const Text(
          '2. Parámetros de Facturación Fiscal Dominicana (DGII)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Control de secuencias correlativas de comprobantes y políticas de corte de servicio.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Próxima Secuencia NCF B01 (Crédito Fiscal)', _ncfB01Controller, '105', Icons.receipt_long_rounded)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Próxima Secuencia NCF B02 (Consumidor Final)', _ncfB02Controller, '230', Icons.receipt_rounded)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField('Días de Gracia antes de Suspensión', _diasGraciaController, '15', Icons.timer_outlined)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Tasa de ITBIS (%)', _itbisController, '18', Icons.percent_rounded)),
          ],
        ),
      ],
    );
  }

  Widget _buildSecurityTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Políticas de Seguridad & Operatividad de la Plataforma',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navyPrimary),
        ),
        const SizedBox(height: 4),
        const Text(
          'Controla el acceso global y medidas preventivas del sistema.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Modo Mantenimiento
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _modoMantenimiento ? const Color(0xFFFEF2F2) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _modoMantenimiento ? Colors.red.shade300 : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _modoMantenimiento ? Colors.red.shade100 : Colors.blueGrey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.construction_rounded, color: _modoMantenimiento ? Colors.red.shade700 : Colors.blueGrey.shade700),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modo Mantenimiento Global',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _modoMantenimiento ? Colors.red.shade900 : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Si se activa, los directores, docentes y padres verán un aviso de mantenimiento temporal.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _modoMantenimiento,
                activeColor: Colors.red.shade700,
                onChanged: (val) => setState(() => _modoMantenimiento = val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Exigir 2FA
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.navyPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.phonelink_lock_rounded, color: AppColors.navyPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Exigir Doble Factor de Autenticación (2FA)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Obliga a los usuarios con rol Superadmin y Contable a confirmar código de seguridad al iniciar sesión.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _exigir2FA,
                activeColor: AppColors.navyPrimary,
                onChanged: (val) => setState(() => _exigir2FA = val),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Longitud mínima de contraseña
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.password_rounded, color: Color(0xFF0284C7)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Longitud Mínima de Contraseña',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Actualmente fijado en $_minPasswordLength caracteres.',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              DropdownButton<int>(
                value: _minPasswordLength,
                items: [6, 8, 10, 12].map((l) {
                  return DropdownMenuItem<int>(
                    value: l,
                    child: Text('$l caracteres'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _minPasswordLength = val);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navyPrimary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
          ),
        ),
      ],
    );
  }
}
