import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Modal interactivo que desglosa el Modelo de Negocio, Pricing y Proyecciones SaaS de EDUNEX
/// basado en el documento oficial: "EDUNEX - Esquema Integral CRM Escolar".
class BusinessModelDialog extends StatefulWidget {
  const BusinessModelDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const BusinessModelDialog(),
    );
  }

  @override
  State<BusinessModelDialog> createState() => _BusinessModelDialogState();
}

class _BusinessModelDialogState extends State<BusinessModelDialog> {
  double _simulatedSchools = 20; // Default a 20 colegios (Etapa 2)
  double _arpu = 7500; // ARPU promedio en RD$

  @override
  Widget build(BuildContext context) {
    final mrr = _simulatedSchools * _arpu;
    final arr = mrr * 12;
    final marketShare = (_simulatedSchools / 650.0) * 100.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surfaceWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 850),
        child: Column(
          children: [
            // Cabecera institucional
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navyPrimary, AppColors.electricBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modelo de Negocio & Arquitectura Comercial EDUNEX',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Estrategia SaaS, monetización por sucursal, cuenta familiar y dimensionamiento de mercado.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Contenido Scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. PROPUESTA DE VALOR & POSICIONAMIENTO
                    _buildSectionCard(
                      icon: Icons.star_rounded,
                      color: AppColors.electricBlue,
                      title: '1. Propuesta de Valor y Principio Central',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.electricBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.electricBlue.withValues(alpha: 0.25)),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.format_quote_rounded, color: AppColors.electricBlue, size: 28),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '“Digitalizamos la relación completa entre el colegio y las familias, centralizando operación, servicios y cobros en una cuenta familiar única.”',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navyDark,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '• Para el colegio: una sola plataforma para administrar estudiantes, familias, dinero y servicios.\n'
                            '• Para los padres: una sola cuenta familiar para gestionar colegiatura, cuido, transporte, uniformes y eventos de todos sus hijos.\n'
                            '• Principio Financiero: Todo servicio contratado por una familia se convierte automáticamente en un cargo dentro de la misma cuenta, eliminando procesos paralelos y pagos dispersos.',
                            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 2. TABLA SIMPLIFICADA DE PRECIOS Y MONETIZACIÓN
                    _buildSectionCard(
                      icon: Icons.price_check_rounded,
                      color: AppColors.accentGreen,
                      title: '2. Tabla Simplificada de Precios & Configuración por Sucursal',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Estructura de precios base mensual para colegios privados en República Dominicana:',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isCompact = constraints.maxWidth < 720;
                              if (isCompact) {
                                return Column(
                                  children: [
                                    _buildPricePlanCard(
                                      title: '1 Sucursal',
                                      subtitle: 'Sede Principal (Base)',
                                      price: 'RD\$ 7,000',
                                      period: '/ mes',
                                      isPopular: true,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildPricePlanCard(
                                      title: '2 Sucursales',
                                      subtitle: 'Sede Central + 1 Anexo',
                                      price: 'RD\$ 10,000 – 11,000',
                                      period: '/ mes',
                                      isPopular: false,
                                    ),
                                    const SizedBox(height: 10),
                                    _buildPricePlanCard(
                                      title: '3+ Sucursales',
                                      subtitle: 'Red Escolar Multicampus',
                                      price: 'RD\$ 13,000 – 15,000',
                                      period: '/ mes',
                                      isPopular: false,
                                    ),
                                  ],
                                );
                              }
                              return Row(
                                children: [
                                  Expanded(
                                    child: _buildPricePlanCard(
                                      title: '1 Sucursal',
                                      subtitle: 'Sede Principal (Base)',
                                      price: 'RD\$ 7,000',
                                      period: '/ mes',
                                      isPopular: true,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildPricePlanCard(
                                      title: '2 Sucursales',
                                      subtitle: 'Sede Central + 1 Anexo',
                                      price: 'RD\$ 10,000 – 11,000',
                                      period: '/ mes',
                                      isPopular: false,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildPricePlanCard(
                                      title: '3+ Sucursales',
                                      subtitle: 'Red Escolar Multicampus',
                                      price: 'RD\$ 13,000 – 15,000',
                                      period: '/ mes',
                                      isPopular: false,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ingresos Adicionales Posibles (Add-ons & Expansión de ARPU):',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.navyPrimary),
                                ),
                                SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Chip(
                                      label: Text('Implementación y migración inicial', style: TextStyle(fontSize: 11)),
                                      backgroundColor: Colors.white,
                                    ),
                                    Chip(
                                      label: Text('Facturación electrónica DGII', style: TextStyle(fontSize: 11)),
                                      backgroundColor: Colors.white,
                                    ),
                                    Chip(
                                      label: Text('WhatsApp y mensajería transaccional', style: TextStyle(fontSize: 11)),
                                      backgroundColor: Colors.white,
                                    ),
                                    Chip(
                                      label: Text('Módulo de uniformes y tienda escolar', style: TextStyle(fontSize: 11)),
                                      backgroundColor: Colors.white,
                                    ),
                                    Chip(
                                      label: Text('Servicio avanzado de rutas GPS en vivo', style: TextStyle(fontSize: 11)),
                                      backgroundColor: Colors.white,
                                    ),
                                    Chip(
                                      label: Text('Soporte premium personalizado', style: TextStyle(fontSize: 11)),
                                      backgroundColor: Colors.white,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 3. SIMULADOR INTERACTIVO DE INGRESOS SAAS
                    _buildSectionCard(
                      icon: Icons.calculate_rounded,
                      color: AppColors.accentOrange,
                      title: '3. Simulador Interactivo de Ingresos SaaS (MRR / ARR)',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ajusta el número de colegios clientes para proyectar el flujo recurrente mensual y anual:',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'Colegios Clientes: ${_simulatedSchools.toInt()}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navyDark),
                              ),
                              const Spacer(),
                              Text(
                                'ARPU Promedio: RD\$ ${_arpu.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Slider(
                            value: _simulatedSchools,
                            min: 1,
                            max: 130,
                            divisions: 129,
                            activeColor: AppColors.electricBlue,
                            onChanged: (val) => setState(() => _simulatedSchools = val),
                          ),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              const Text('1 colegio', style: TextStyle(fontSize: 11, color: AppColors.slateGray)),
                              TextButton(
                                onPressed: () => setState(() => _simulatedSchools = 5),
                                child: const Text('Meta 5 (Piloto)', style: TextStyle(fontSize: 11)),
                              ),
                              TextButton(
                                onPressed: () => setState(() => _simulatedSchools = 20),
                                child: const Text('Meta 20 (Comercial)', style: TextStyle(fontSize: 11)),
                              ),
                              TextButton(
                                onPressed: () => setState(() => _simulatedSchools = 50),
                                child: const Text('Meta 50 (Escala)', style: TextStyle(fontSize: 11)),
                              ),
                              const Text('130 colegios (20%)', style: TextStyle(fontSize: 11, color: AppColors.slateGray)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: LayoutBuilder(
                              builder: (context, box) {
                                final isCompact = box.maxWidth < 550;
                                if (isCompact) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('MRR Proyectado (Mensual):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(
                                            'RD\$ ${mrr.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                                            style: const TextStyle(color: AppColors.cyanLight, fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const Divider(color: Colors.white24, height: 20),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('ARR Proyectado (Anual):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(
                                            'RD\$ ${arr.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                                            style: const TextStyle(color: AppColors.accentGreen, fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const Divider(color: Colors.white24, height: 20),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Penetración del Segmento:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${marketShare.toStringAsFixed(1)}% (de 650 colegios)',
                                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('MRR Proyectado (Mensual):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(
                                            'RD\$ ${mrr.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                                            style: const TextStyle(color: AppColors.cyanLight, fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(width: 1, height: 40, color: Colors.white24),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('ARR Proyectado (Anual):', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(
                                            'RD\$ ${arr.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                                            style: const TextStyle(color: AppColors.accentGreen, fontSize: 20, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(width: 1, height: 40, color: Colors.white24),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Penetración del Segmento:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${marketShare.toStringAsFixed(1)}% (de 650)',
                                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 4. OBJETIVOS COMERCIALES POR ETAPA & DIMENSIONAMIENTO MINERD
                    _buildSectionCard(
                      icon: Icons.flag_rounded,
                      color: AppColors.navyPrimary,
                      title: '4. Objetivos Comerciales por Etapa & Mercado MINERD',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dimensionamiento oficial MINERD Gran Santo Domingo: 1,598 colegios privados (315,832 alumnos). Universo foco: 650–700 colegios pequeños (50–300 estudiantes).',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),
                          Table(
                            border: TableBorder.all(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(8)),
                            columnWidths: const {
                              0: FlexColumnWidth(1.2),
                              1: FlexColumnWidth(1.0),
                              2: FlexColumnWidth(1.4),
                              3: FlexColumnWidth(2.4),
                            },
                            children: const [
                              TableRow(
                                decoration: BoxDecoration(color: Color(0xFFF1F5F9)),
                                children: [
                                  Padding(padding: EdgeInsets.all(8), child: Text('Etapa', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('Clientes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('MRR Base', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('Objetivo Estratégico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                                ],
                              ),
                              TableRow(
                                children: [
                                  Padding(padding: EdgeInsets.all(8), child: Text('1. Validación', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('5 colegios', style: TextStyle(fontSize: 12))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('≈ RD\$ 35,000', style: TextStyle(fontSize: 12, color: AppColors.navyPrimary, fontWeight: FontWeight.bold))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('Comprobar adopción y resolución de fricciones reales.', style: TextStyle(fontSize: 12))),
                                ],
                              ),
                              TableRow(
                                children: [
                                  Padding(padding: EdgeInsets.all(8), child: Text('2. Producto', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('20 colegios', style: TextStyle(fontSize: 12))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('≈ RD\$ 140,000', style: TextStyle(fontSize: 12, color: AppColors.navyPrimary, fontWeight: FontWeight.bold))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('Establecer un SaaS comercial pequeño y repetible.', style: TextStyle(fontSize: 12))),
                                ],
                              ),
                              TableRow(
                                children: [
                                  Padding(padding: EdgeInsets.all(8), child: Text('3. Escala', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('50 colegios', style: TextStyle(fontSize: 12))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('≈ RD\$ 350,000', style: TextStyle(fontSize: 12, color: AppColors.navyPrimary, fontWeight: FontWeight.bold))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('Consolidar operación, soporte y ventas (7.7% del foco).', style: TextStyle(fontSize: 12))),
                                ],
                              ),
                              TableRow(
                                children: [
                                  Padding(padding: EdgeInsets.all(8), child: Text('4. Expansión', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('100 colegios', style: TextStyle(fontSize: 12))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('≈ RD\$ 700,000', style: TextStyle(fontSize: 12, color: AppColors.navyPrimary, fontWeight: FontWeight.bold))),
                                  Padding(padding: EdgeInsets.all(8), child: Text('≈ RD\$ 8.4 MM/año antes de costos + servicios premium.', style: TextStyle(fontSize: 12))),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer con botón de cierre
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Entendido'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navyDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildPricePlanCard({
    required String title,
    required String subtitle,
    required String price,
    required String period,
    required bool isPopular,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPopular ? AppColors.navyPrimary.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPopular ? AppColors.electricBlue : const Color(0xFFCBD5E1),
          width: isPopular ? 1.8 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isPopular)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.electricBlue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'PRECIO BASE REFERENCIA',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navyDark)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.navyPrimary),
                ),
                const SizedBox(width: 4),
                Text(period, style: const TextStyle(fontSize: 11, color: AppColors.slateGray)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
