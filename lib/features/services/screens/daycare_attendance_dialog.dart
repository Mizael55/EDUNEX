import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

/// Modelo de registro de asistencia en cuido vespertino
class DaycareRecord {
  final String id;
  final String studentName;
  final String grade;
  final String parentContact;
  final String checkInTime;
  String? checkOutTime;
  String? pickedUpBy;
  bool isCheckedOut;

  DaycareRecord({
    required this.id,
    required this.studentName,
    required this.grade,
    required this.parentContact,
    required this.checkInTime,
    this.checkOutTime,
    this.pickedUpBy,
    this.isCheckedOut = false,
  });
}

/// Modal interactivo de Control de Asistencia en Servicio de Cuido
class DaycareAttendanceDialog extends StatefulWidget {
  const DaycareAttendanceDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const DaycareAttendanceDialog(),
    );
  }

  @override
  State<DaycareAttendanceDialog> createState() => _DaycareAttendanceDialogState();
}

class _DaycareAttendanceDialogState extends State<DaycareAttendanceDialog> {
  final List<DaycareRecord> _records = [
    DaycareRecord(
      id: 'cuido-1',
      studentName: 'Mateo Pérez González',
      grade: '1ro de Primaria',
      parentContact: '809-555-0150 (Roberto Pérez)',
      checkInTime: '03:15 PM',
      isCheckedOut: false,
    ),
    DaycareRecord(
      id: 'cuido-2',
      studentName: 'Sofía Pérez González',
      grade: 'Kinder A',
      parentContact: '809-555-0150 (Carmen González)',
      checkInTime: '03:10 PM',
      checkOutTime: '05:30 PM',
      pickedUpBy: 'Carmen González (Madre)',
      isCheckedOut: true,
    ),
    DaycareRecord(
      id: 'cuido-3',
      studentName: 'Lucas Castillo Rosario',
      grade: '2do de Primaria',
      parentContact: '809-555-0899 (Laura Rosario)',
      checkInTime: '03:00 PM',
      isCheckedOut: false,
    ),
  ];

  void _recordCheckout(DaycareRecord record) {
    final nameCtrl = TextEditingController(text: 'Tutor Autorizado');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Registrar Retiro del Alumno'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alumno: ${record.studentName}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Persona que retira *',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              final now = TimeOfDay.now();
              final timeStr = '${now.hourOfPeriod}:${now.minute.toString().padLeft(2, "0")} ${now.period == DayPeriod.am ? "AM" : "PM"}';
              setState(() {
                record.isCheckedOut = true;
                record.checkOutTime = timeStr;
                record.pickedUpBy = nameCtrl.text.trim();
              });
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Retiro registrado para ${record.studentName} a las $timeStr'),
                  backgroundColor: AppColors.navyPrimary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen, foregroundColor: Colors.white),
            child: const Text('Confirmar Retiro'),
          ),
        ],
      ),
    );
  }

  void _addNewStudent() {
    final nameCtrl = TextEditingController();
    final gradeCtrl = TextEditingController(text: '1ro de Primaria');
    final contactCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ingresar Alumno a Cuido Hoy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nombre del Alumno *')),
            const SizedBox(height: 10),
            TextField(controller: gradeCtrl, decoration: const InputDecoration(labelText: 'Grado / Curso')),
            const SizedBox(height: 10),
            TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contacto del Tutor')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final now = TimeOfDay.now();
              final timeStr = '${now.hourOfPeriod}:${now.minute.toString().padLeft(2, "0")} ${now.period == DayPeriod.am ? "AM" : "PM"}';
              setState(() {
                _records.insert(
                  0,
                  DaycareRecord(
                    id: 'cuido-${DateTime.now().millisecondsSinceEpoch}',
                    studentName: nameCtrl.text.trim(),
                    grade: gradeCtrl.text.trim(),
                    parentContact: contactCtrl.text.trim(),
                    checkInTime: timeStr,
                  ),
                );
              });
              Navigator.of(ctx).pop();
            },
            child: const Text('Registrar Entrada'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = _records.where((r) => !r.isCheckedOut).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surfaceWhite,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 750),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.navyPrimary, AppColors.electricBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.child_care_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Control de Asistencia - Cuido Vespertino',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Horario: 3:00 PM - 6:00 PM • $activeCount niños actualmente en sala',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.electricBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Niños en Sala: $activeCount',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyPrimary, fontSize: 13),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _addNewStudent,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('Registrar Entrada'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navyPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _records.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final r = _records[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: r.isCheckedOut ? const Color(0xFFF8FAFC) : AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: r.isCheckedOut ? const Color(0xFFE2E8F0) : const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: r.isCheckedOut ? const Color(0xFFE2E8F0) : AppColors.electricBlue.withValues(alpha: 0.15),
                          child: Icon(
                            r.isCheckedOut ? Icons.check_rounded : Icons.face_rounded,
                            color: r.isCheckedOut ? AppColors.textSecondary : AppColors.electricBlue,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.studentName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: r.isCheckedOut ? AppColors.textSecondary : AppColors.textPrimary,
                                ),
                              ),
                              Text('${r.grade} • ${r.parentContact}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('Entrada: ${r.checkInTime}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  if (r.isCheckedOut) ...[
                                    const SizedBox(width: 10),
                                    Text('Retirado: ${r.checkOutTime ?? ""} (${r.pickedUpBy ?? ""})', style: const TextStyle(fontSize: 11, color: Color(0xFF15803D), fontWeight: FontWeight.bold)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!r.isCheckedOut)
                          ElevatedButton(
                            onPressed: () => _recordCheckout(r),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Registrar Retiro', style: TextStyle(fontSize: 12)),
                          )
                        else
                          const Chip(
                            label: Text('Entregado', style: TextStyle(fontSize: 11, color: Color(0xFF15803D))),
                            backgroundColor: Color(0xFFDCFCE7),
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.navyPrimary, foregroundColor: Colors.white),
                    child: const Text('Cerrar'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
