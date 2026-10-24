import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/academic_models.dart';
import '../models/grade_report.dart';

/// Repositorio de Gestión Académica Centralizada, Cursos, Secciones,
/// Estudiantes, Profesores, Asignaciones y Boletines de Calificaciones (Issue #20)
class AcademicRepository {
  final bool useDemoFallback;

  AcademicRepository({this.useDemoFallback = true}) {
    _initDemoData();
    _loadFromStorage();
  }

  // Claves de persistencia
  static const String _prefKeyCourses = 'edunex_academic_courses_v1';
  static const String _prefKeySections = 'edunex_academic_sections_v1';
  static const String _prefKeySubjects = 'edunex_academic_subjects_v1';
  static const String _prefKeyTeachers = 'edunex_academic_teachers_v1';
  static const String _prefKeyAssignments = 'edunex_academic_assignments_v1';
  static const String _prefKeyEnrollments = 'edunex_academic_enrollments_v1';
  static const String _prefKeyClassroomEvents = 'edunex_academic_events_v1';

  // Listados en memoria
  final List<AcademicCourse> _courses = [];
  final List<AcademicSection> _sections = [];
  final List<AcademicSubject> _subjects = [];
  final List<AcademicTeacher> _teachers = [];
  final List<TeacherAcademicAssignment> _teacherAssignments = [];
  final List<StudentEnrollment> _enrollments = [];
  final List<ClassroomEvent> _classroomEvents = [];

  // Reportes de calificaciones (MINERD)
  static final List<StudentGradeReport> _reports = [
    StudentGradeReport(
      id: 'grade-rep-001',
      studentId: 'f0000000-0000-0000-0000-000000000001',
      studentName: 'Mateo Pérez González',
      matricula: 'EST-2026-01',
      grado: '1ro de Primaria',
      seccion: 'Sección A',
      anioEscolar: '2025-2026',
      calificacionConducta: 'A - Sobresaliente',
      observacionesDocente:
          'Mateo demuestra un excelente compromiso académico, liderazgo en proyectos colaborativos y destacada destreza en lectoescritura y razonamiento lógico-matemático.',
      materias: const [
        SubjectGrade(
          materia: 'Matemáticas',
          periodo1: 92,
          periodo2: 95,
          periodo3: 88,
          periodo4: 94,
          docente: 'Lic. Rosaura Peña',
        ),
        SubjectGrade(
          materia: 'Lengua Española',
          periodo1: 90,
          periodo2: 91,
          periodo3: 94,
          periodo4: 92,
          docente: 'Lic. Marcos Almonte',
        ),
        SubjectGrade(
          materia: 'Ciencias de la Naturaleza',
          periodo1: 88,
          periodo2: 89,
          periodo3: 90,
          periodo4: 91,
          docente: 'Dra. Elena Vásquez',
        ),
        SubjectGrade(
          materia: 'Ciencias Sociales',
          periodo1: 85,
          periodo2: 90,
          periodo3: 88,
          periodo4: 92,
          docente: 'Lic. Fernando Ruiz',
        ),
        SubjectGrade(
          materia: 'Inglés Técnico',
          periodo1: 96,
          periodo2: 98,
          periodo3: 95,
          periodo4: 97,
          docente: 'Lic. Sarah Jenkins',
        ),
        SubjectGrade(
          materia: 'Educación Artística',
          periodo1: 95,
          periodo2: 94,
          periodo3: 96,
          periodo4: 98,
          docente: 'Lic. David Batista',
        ),
        SubjectGrade(
          materia: 'Educación Física',
          periodo1: 90,
          periodo2: 92,
          periodo3: 94,
          periodo4: 95,
          docente: 'Lic. José Tavárez',
        ),
        SubjectGrade(
          materia: 'Formación Humana & Ética',
          periodo1: 95,
          periodo2: 96,
          periodo3: 98,
          periodo4: 96,
          docente: 'Lic. Rosaura Peña',
        ),
      ],
    ),
    StudentGradeReport(
      id: 'grade-rep-002',
      studentId: 'f0000000-0000-0000-0000-000000000002',
      studentName: 'Sofía Pérez González',
      matricula: 'EST-2026-02',
      grado: 'Kinder',
      seccion: 'Sección A',
      anioEscolar: '2025-2026',
      calificacionConducta: 'A - Sobresaliente',
      observacionesDocente:
          'Sofía se integra con alegría en todas las rutinas pedagógicas, manifiesta un alto nivel de empatía con sus compañeros y desarrolla con soltura sus habilidades motoras finas.',
      materias: const [
        SubjectGrade(
          materia: 'Dimensión Cognitiva & Lógica',
          periodo1: 95,
          periodo2: 98,
          periodo3: 96,
          periodo4: 97,
          docente: 'Tía Carolina Gómez',
        ),
        SubjectGrade(
          materia: 'Expresión Corporal & Psicomotricidad',
          periodo1: 92,
          periodo2: 95,
          periodo3: 94,
          periodo4: 96,
          docente: 'Tía Carolina Gómez',
        ),
        SubjectGrade(
          materia: 'Lenguaje & Comunicación Temprana',
          periodo1: 96,
          periodo2: 94,
          periodo3: 98,
          periodo4: 95,
          docente: 'Tía Carolina Gómez',
        ),
        SubjectGrade(
          materia: 'Desarrollo Socioafectivo',
          periodo1: 98,
          periodo2: 96,
          periodo3: 97,
          periodo4: 99,
          docente: 'Tía Carolina Gómez',
        ),
        SubjectGrade(
          materia: 'Sensibilidad Musical & Artística',
          periodo1: 94,
          periodo2: 97,
          periodo3: 95,
          periodo4: 98,
          docente: 'Prof. Lucas Ortiz',
        ),
      ],
    ),
    StudentGradeReport(
      id: 'grade-rep-003',
      studentId: 'f0000000-0000-0000-0000-000000000003',
      studentName: 'Lucas Ramírez Méndez',
      matricula: 'EST-2026-03',
      grado: '1ro de Primaria',
      seccion: 'Sección A',
      anioEscolar: '2025-2026',
      calificacionConducta: 'B+ - Muy Bueno',
      observacionesDocente:
          'Lucas muestra buen desempeño general. Se sugiere continuar reforzando la caligrafía y el hábito de lectura diaria en el hogar.',
      materias: const [
        SubjectGrade(
          materia: 'Matemáticas',
          periodo1: 84,
          periodo2: 86,
          periodo3: 82,
          periodo4: 85,
          docente: 'Lic. Rosaura Peña',
        ),
        SubjectGrade(
          materia: 'Lengua Española',
          periodo1: 78,
          periodo2: 80,
          periodo3: 82,
          periodo4: 84,
          docente: 'Lic. Marcos Almonte',
        ),
        SubjectGrade(
          materia: 'Ciencias de la Naturaleza',
          periodo1: 82,
          periodo2: 85,
          periodo3: 86,
          periodo4: 88,
          docente: 'Dra. Elena Vásquez',
        ),
        SubjectGrade(
          materia: 'Ciencias Sociales',
          periodo1: 80,
          periodo2: 82,
          periodo3: 84,
          periodo4: 83,
          docente: 'Lic. Fernando Ruiz',
        ),
        SubjectGrade(
          materia: 'Inglés Técnico',
          periodo1: 88,
          periodo2: 90,
          periodo3: 89,
          periodo4: 91,
          docente: 'Lic. Sarah Jenkins',
        ),
        SubjectGrade(
          materia: 'Educación Artística',
          periodo1: 86,
          periodo2: 88,
          periodo3: 89,
          periodo4: 90,
          docente: 'Lic. David Batista',
        ),
      ],
    ),
  ];

  void _initDemoData() {
    const defaultColegio = 'col-1';

    // 1. Cursos
    _courses.addAll([
      const AcademicCourse(
        id: 'cur-001',
        colegioId: defaultColegio,
        nombre: 'Kinder',
        nivel: 'Inicial',
        anioEscolar: '2025-2026',
        materiasIds: ['mat-008'],
        orden: 1,
      ),
      const AcademicCourse(
        id: 'cur-002',
        colegioId: defaultColegio,
        nombre: '1ro de Primaria',
        nivel: 'Primaria',
        anioEscolar: '2025-2026',
        materiasIds: ['mat-001', 'mat-002', 'mat-003', 'mat-004', 'mat-005', 'mat-006', 'mat-007'],
        orden: 2,
      ),
      const AcademicCourse(
        id: 'cur-003',
        colegioId: defaultColegio,
        nombre: '2do de Primaria',
        nivel: 'Primaria',
        anioEscolar: '2025-2026',
        materiasIds: ['mat-001', 'mat-002', 'mat-003', 'mat-004', 'mat-005'],
        orden: 3,
      ),
      const AcademicCourse(
        id: 'cur-004',
        colegioId: defaultColegio,
        nombre: '1ro de Secundaria',
        nivel: 'Secundaria',
        anioEscolar: '2025-2026',
        materiasIds: ['mat-001', 'mat-002', 'mat-003', 'mat-004', 'mat-005'],
        orden: 4,
      ),
    ]);

    // 2. Secciones
    _sections.addAll([
      const AcademicSection(
        id: 'sec-001',
        colegioId: defaultColegio,
        cursoId: 'cur-001',
        cursoNombre: 'Kinder',
        nombre: 'Sección A',
        anioEscolar: '2025-2026',
        capacidadEstudiantes: 25,
        aula: 'Pabellón Inicial - Aula 01',
        profesorTitularId: 'tch-007',
        profesorTitularNombre: 'Tía Carolina Gómez',
      ),
      const AcademicSection(
        id: 'sec-002',
        colegioId: defaultColegio,
        cursoId: 'cur-002',
        cursoNombre: '1ro de Primaria',
        nombre: 'Sección A',
        anioEscolar: '2025-2026',
        capacidadEstudiantes: 30,
        aula: 'Edificio Central - Aula 101',
        profesorTitularId: 'tch-001',
        profesorTitularNombre: 'Lic. Rosaura Peña',
      ),
      const AcademicSection(
        id: 'sec-003',
        colegioId: defaultColegio,
        cursoId: 'cur-002',
        cursoNombre: '1ro de Primaria',
        nombre: 'Sección B',
        anioEscolar: '2025-2026',
        capacidadEstudiantes: 30,
        aula: 'Edificio Central - Aula 102',
        profesorTitularId: 'tch-002',
        profesorTitularNombre: 'Lic. Marcos Almonte',
      ),
      const AcademicSection(
        id: 'sec-004',
        colegioId: defaultColegio,
        cursoId: 'cur-003',
        cursoNombre: '2do de Primaria',
        nombre: 'Sección A',
        anioEscolar: '2025-2026',
        capacidadEstudiantes: 30,
        aula: 'Edificio Central - Aula 201',
        profesorTitularId: 'tch-004',
        profesorTitularNombre: 'Lic. Fernando Ruiz',
      ),
      const AcademicSection(
        id: 'sec-005',
        colegioId: defaultColegio,
        cursoId: 'cur-004',
        cursoNombre: '1ro de Secundaria',
        nombre: 'Sección A',
        anioEscolar: '2025-2026',
        capacidadEstudiantes: 32,
        aula: 'Edificio Secundaria - Aula 301',
        profesorTitularId: 'tch-006',
        profesorTitularNombre: 'Lic. David Batista',
      ),
    ]);

    // 3. Materias
    _subjects.addAll([
      const AcademicSubject(
        id: 'mat-001',
        colegioId: defaultColegio,
        nombre: 'Matemáticas',
        codigo: 'MAT-101',
        horasSemanales: 5,
        descripcion: 'Aritmética, geometría básica, razonamiento lógico y resolución de problemas.',
        cursosIds: ['cur-002', 'cur-003', 'cur-004'],
        colorHex: '#1E3A8A',
      ),
      const AcademicSubject(
        id: 'mat-002',
        colegioId: defaultColegio,
        nombre: 'Lengua Española',
        codigo: 'ESP-101',
        horasSemanales: 5,
        descripcion: 'Comprensión lectora, gramática, ortografía y expresión escrita.',
        cursosIds: ['cur-002', 'cur-003', 'cur-004'],
        colorHex: '#047857',
      ),
      const AcademicSubject(
        id: 'mat-003',
        colegioId: defaultColegio,
        nombre: 'Ciencias de la Naturaleza',
        codigo: 'NAT-101',
        horasSemanales: 4,
        descripcion: 'Biología, entorno natural, método científico y cuidado del medio ambiente.',
        cursosIds: ['cur-002', 'cur-003', 'cur-004'],
        colorHex: '#0284C7',
      ),
      const AcademicSubject(
        id: 'mat-004',
        colegioId: defaultColegio,
        nombre: 'Ciencias Sociales',
        codigo: 'SOC-101',
        horasSemanales: 4,
        descripcion: 'Historia dominicana, geografía y valores cívicos y ciudadanos.',
        cursosIds: ['cur-002', 'cur-003', 'cur-004'],
        colorHex: '#B45309',
      ),
      const AcademicSubject(
        id: 'mat-005',
        colegioId: defaultColegio,
        nombre: 'Inglés Técnico',
        codigo: 'ING-101',
        horasSemanales: 3,
        descripcion: 'Vocabulario, fonética y conversación en segundo idioma.',
        cursosIds: ['cur-002', 'cur-003', 'cur-004'],
        colorHex: '#6D28D9',
      ),
      const AcademicSubject(
        id: 'mat-006',
        colegioId: defaultColegio,
        nombre: 'Educación Artística',
        codigo: 'ART-101',
        horasSemanales: 2,
        descripcion: 'Artes visuales, plástica, teatro y expresión creativa.',
        cursosIds: ['cur-002', 'cur-003'],
        colorHex: '#DB2777',
      ),
      const AcademicSubject(
        id: 'mat-007',
        colegioId: defaultColegio,
        nombre: 'Educación Física',
        codigo: 'EFI-101',
        horasSemanales: 2,
        descripcion: 'Acondicionamiento físico, psicomotricidad y deportes de equipo.',
        cursosIds: ['cur-002', 'cur-003', 'cur-004'],
        colorHex: '#EA580C',
      ),
      const AcademicSubject(
        id: 'mat-008',
        colegioId: defaultColegio,
        nombre: 'Desarrollo Integral Temprano',
        codigo: 'INI-001',
        horasSemanales: 20,
        descripcion: 'Estimulación multisensorial, motricidad fina y desarrollo cognitivo infantil.',
        cursosIds: ['cur-001'],
        colorHex: '#059669',
      ),
    ]);

    // 4. Profesores
    _teachers.addAll([
      AcademicTeacher(
        id: 'tch-001',
        colegioId: defaultColegio,
        nombreCompleto: 'Lic. Rosaura Peña',
        cedula: '001-1234567-8',
        email: 'rosaura.pena@edunex.edu.do',
        telefono: '(809) 555-0101',
        especialidad: 'Matemáticas & Ciencias',
        estado: 'Activo',
        materiasQuePuedeImpartir: ['Matemáticas', 'Ciencias de la Naturaleza', 'Formación Humana & Ética'],
        estudios: 'Licenciatura en Educación mención Matemáticas (UASD)',
        maestria: 'Maestría en Didáctica de las Ciencias Exactas (INTEC)',
        experiencia: '9 años de docencia en nivel básico y secundaria',
        referencias: 'Colegio San Judas Tadeo - Lic. Marcos Díaz (809-555-1234)',
        tieneCartaBuenaConducta: true,
        materiasQueImparte: ['Matemáticas', 'Formación Humana & Ética'],
        calificacionDesempeno: 4.9,
        usuarioAcceso: 'prof.rosaura.pena',
        claveTemporal: 'Docente2026!',
        evaluacionesDirector: [
          TeacherEvaluationRecord(
            id: 'eval-001',
            fecha: DateTime(2025, 11, 20),
            directorNombre: 'Ernesto De Jesus',
            puntaje: 5.0,
            criterio: 'Pedagogía y Gestión de Aula',
            comentario: 'Excelente dominio de aula, dinamismo pedagógico y puntualidad intachable.',
          ),
        ],
      ),
      const AcademicTeacher(
        id: 'tch-002',
        colegioId: defaultColegio,
        nombreCompleto: 'Lic. Marcos Almonte',
        cedula: '001-9876543-2',
        email: 'marcos.almonte@edunex.edu.do',
        telefono: '(809) 555-0102',
        especialidad: 'Lengua y Literatura',
        estado: 'Activo',
        materiasQuePuedeImpartir: ['Lengua Española', 'Lectura Crítica'],
        estudios: 'Licenciatura en Letras Hispánicas (PUCMM)',
        maestria: 'Especialidad en Promoción y Animación a la Lectura',
        experiencia: '7 años de experiencia docente',
        referencias: 'Instituto Calasanz - Dra. Miriam Soto (809-555-3344)',
        tieneCartaBuenaConducta: true,
        materiasQueImparte: ['Lengua Española'],
        calificacionDesempeno: 4.7,
        usuarioAcceso: 'prof.marcos.almonte',
        claveTemporal: 'Docente2026!',
      ),
      const AcademicTeacher(
        id: 'tch-003',
        colegioId: defaultColegio,
        nombreCompleto: 'Dra. Elena Vásquez',
        cedula: '001-4567890-1',
        email: 'elena.vasquez@edunex.edu.do',
        telefono: '(809) 555-0103',
        especialidad: 'Ciencias Naturales & Química',
        estado: 'Activo',
        materiasQuePuedeImpartir: ['Ciencias de la Naturaleza', 'Química', 'Biología'],
        estudios: 'Doctorado en Educación y Bioquímica (UNPHU)',
        experiencia: '12 años de trayectoria docente y de laboratorio',
        referencias: 'Colegio Loyola - Lic. Carlos Peña (809-555-8822)',
        tieneCartaBuenaConducta: true,
        materiasQueImparte: ['Ciencias de la Naturaleza'],
        calificacionDesempeno: 5.0,
        usuarioAcceso: 'prof.elena.vasquez',
        claveTemporal: 'Docente2026!',
      ),
      const AcademicTeacher(
        id: 'tch-004',
        colegioId: defaultColegio,
        nombreCompleto: 'Lic. Fernando Ruiz',
        cedula: '001-3456789-0',
        email: 'fernando.ruiz@edunex.edu.do',
        telefono: '(809) 555-0104',
        especialidad: 'Ciencias Sociales e Historia',
        estado: 'Activo',
        materiasQuePuedeImpartir: ['Ciencias Sociales', 'Cívica', 'Geografía'],
        estudios: 'Licenciatura en Ciencias Sociales (UASD)',
        experiencia: '6 años de experiencia en básica',
        referencias: 'Colegio Claret - P. Juan Morales (809-555-4411)',
        tieneCartaBuenaConducta: true,
        materiasQueImparte: ['Ciencias Sociales'],
        calificacionDesempeno: 4.6,
        usuarioAcceso: 'prof.fernando.ruiz',
        claveTemporal: 'Docente2026!',
      ),
      const AcademicTeacher(
        id: 'tch-005',
        colegioId: defaultColegio,
        nombreCompleto: 'Lic. Sarah Jenkins',
        cedula: '402-1122334-5',
        email: 'sarah.jenkins@edunex.edu.do',
        telefono: '(809) 555-0105',
        especialidad: 'Lenguas Extranjeras (Inglés)',
        estado: 'Activo',
        materiasQuePuedeImpartir: ['Inglés Técnico', 'Conversación en Inglés'],
        estudios: 'BA in Modern Languages & TESOL Certification',
        experiencia: '5 años de enseñanza bilingüe',
        referencias: 'Dominico Americano - Prof. Mark Davis (809-555-6677)',
        tieneCartaBuenaConducta: true,
        materiasQueImparte: ['Inglés Técnico'],
        calificacionDesempeno: 4.8,
        usuarioAcceso: 'prof.sarah.jenkins',
        claveTemporal: 'Docente2026!',
      ),
      const AcademicTeacher(
        id: 'tch-006',
        colegioId: defaultColegio,
        nombreCompleto: 'Lic. David Batista',
        cedula: '001-8899001-2',
        email: 'david.batista@edunex.edu.do',
        telefono: '(809) 555-0106',
        especialidad: 'Artes & Expresión',
        estado: 'Activo',
        materiasQuePuedeImpartir: ['Educación Artística', 'Música', 'Teatro'],
        estudios: 'Licenciatura en Artes Plásticas y Pedagogía (Bellas Artes)',
        experiencia: '8 años de docencia artística',
        referencias: 'Escuela Nacional de Artes Visuales - Lic. Pedro Soto',
        tieneCartaBuenaConducta: true,
        materiasQueImparte: ['Educación Artística'],
        calificacionDesempeno: 4.7,
        usuarioAcceso: 'prof.david.batista',
        claveTemporal: 'Docente2026!',
      ),
      const AcademicTeacher(
        id: 'tch-007',
        colegioId: defaultColegio,
        nombreCompleto: 'Tía Carolina Gómez',
        cedula: '001-7788990-3',
        email: 'carolina.gomez@edunex.edu.do',
        telefono: '(809) 555-0107',
        especialidad: 'Educación Inicial & Parvularia',
        estado: 'Activo',
        materiasQuePuedeImpartir: ['Desarrollo Integral Temprano', 'Psicomotricidad'],
        estudios: 'Licenciatura en Educación Temprana y Estimulación Oportuna (UNIBE)',
        maestria: 'Máster en Neurodesarrollo y Aprendizaje Infantil',
        experiencia: '10 años en educación preescolar',
        referencias: 'Centro Infantil Mis Primeros Pasos - Lic. Altagracia Núñez',
        tieneCartaBuenaConducta: true,
        materiasQueImparte: ['Desarrollo Integral Temprano'],
        calificacionDesempeno: 5.0,
        usuarioAcceso: 'prof.carolina.gomez',
        claveTemporal: 'Docente2026!',
      ),
    ]);

    // 5. Asignaciones Docentes (Profesor -> Materia + Curso + Sección)
    _teacherAssignments.addAll([
      const TeacherAcademicAssignment(
        id: 'asg-001',
        colegioId: defaultColegio,
        profesorId: 'tch-001',
        profesorNombre: 'Lic. Rosaura Peña',
        materiaId: 'mat-001',
        materiaNombre: 'Matemáticas',
        cursoId: 'cur-002',
        cursoNombre: '1ro de Primaria',
        seccionId: 'sec-002',
        seccionNombre: 'Sección A',
        anioEscolar: '2025-2026',
        horarioSemanal: 'Lunes y Miércoles 08:00 - 09:30',
        diaSemana: 'Lunes y Miércoles',
        bloqueHorario: '08:00 - 09:30',
        aula: 'Edificio Central - Aula 101',
      ),
      const TeacherAcademicAssignment(
        id: 'asg-002',
        colegioId: defaultColegio,
        profesorId: 'tch-002',
        profesorNombre: 'Lic. Marcos Almonte',
        materiaId: 'mat-002',
        materiaNombre: 'Lengua Española',
        cursoId: 'cur-002',
        cursoNombre: '1ro de Primaria',
        seccionId: 'sec-002',
        seccionNombre: 'Sección A',
        anioEscolar: '2025-2026',
        horarioSemanal: 'Lunes y Miércoles 09:30 - 11:00',
        diaSemana: 'Lunes y Miércoles',
        bloqueHorario: '09:30 - 11:00',
        aula: 'Edificio Central - Aula 101',
      ),
      const TeacherAcademicAssignment(
        id: 'asg-003',
        colegioId: defaultColegio,
        profesorId: 'tch-003',
        profesorNombre: 'Dra. Elena Vásquez',
        materiaId: 'mat-003',
        materiaNombre: 'Ciencias de la Naturaleza',
        cursoId: 'cur-002',
        cursoNombre: '1ro de Primaria',
        seccionId: 'sec-002',
        seccionNombre: 'Sección A',
        anioEscolar: '2025-2026',
        horarioSemanal: 'Martes y Jueves 08:00 - 09:30',
        diaSemana: 'Martes y Jueves',
        bloqueHorario: '08:00 - 09:30',
        aula: 'Edificio Central - Aula 101',
      ),
      const TeacherAcademicAssignment(
        id: 'asg-004',
        colegioId: defaultColegio,
        profesorId: 'tch-004',
        profesorNombre: 'Lic. Fernando Ruiz',
        materiaId: 'mat-004',
        materiaNombre: 'Ciencias Sociales',
        cursoId: 'cur-002',
        cursoNombre: '1ro de Primaria',
        seccionId: 'sec-002',
        seccionNombre: 'Sección A',
        anioEscolar: '2025-2026',
        horarioSemanal: 'Martes y Jueves 09:30 - 11:00',
        diaSemana: 'Martes y Jueves',
        bloqueHorario: '09:30 - 11:00',
        aula: 'Edificio Central - Aula 101',
      ),
      const TeacherAcademicAssignment(
        id: 'asg-005',
        colegioId: defaultColegio,
        profesorId: 'tch-005',
        profesorNombre: 'Lic. Sarah Jenkins',
        materiaId: 'mat-005',
        materiaNombre: 'Inglés Técnico',
        cursoId: 'cur-002',
        cursoNombre: '1ro de Primaria',
        seccionId: 'sec-002',
        seccionNombre: 'Sección A',
        anioEscolar: '2025-2026',
        horarioSemanal: 'Viernes 08:00 - 09:30',
        diaSemana: 'Viernes',
        bloqueHorario: '08:00 - 09:30',
        aula: 'Edificio Central - Aula 101',
      ),
      const TeacherAcademicAssignment(
        id: 'asg-006',
        colegioId: defaultColegio,
        profesorId: 'tch-007',
        profesorNombre: 'Tía Carolina Gómez',
        materiaId: 'mat-008',
        materiaNombre: 'Desarrollo Integral Temprano',
        cursoId: 'cur-001',
        cursoNombre: 'Kinder',
        seccionId: 'sec-001',
        seccionNombre: 'Sección A',
        anioEscolar: '2025-2026',
        horarioSemanal: 'Lunes a Viernes 08:00 - 12:00',
        diaSemana: 'Lunes a Viernes',
        bloqueHorario: '08:00 - 12:00',
        aula: 'Pabellón Inicial - Aula 01',
      ),
    ]);

    // 6. Matrículas de Estudiantes
    _enrollments.addAll([
      StudentEnrollment(
        id: 'enr-001',
        colegioId: defaultColegio,
        estudianteId: 'f0000000-0000-0000-0000-000000000001',
        estudianteNombre: 'Mateo Pérez González',
        matricula: 'EST-2026-01',
        cursoId: 'cur-002',
        cursoNombre: '1ro de Primaria',
        seccionId: 'sec-002',
        seccionNombre: 'Sección A',
        anioEscolar: '2025-2026',
        fechaAsignacion: DateTime(2025, 8, 15),
        aula: 'Edificio Central - Aula 101',
        usuarioAcceso: 'est.est202601',
        claveTemporal: 'Estudiante2026!',
      ),
      StudentEnrollment(
        id: 'enr-002',
        colegioId: defaultColegio,
        estudianteId: 'f0000000-0000-0000-0000-000000000002',
        estudianteNombre: 'Sofía Pérez González',
        matricula: 'EST-2026-02',
        cursoId: 'cur-001',
        cursoNombre: 'Kinder',
        seccionId: 'sec-001',
        seccionNombre: 'Sección A',
        anioEscolar: '2025-2026',
        fechaAsignacion: DateTime(2025, 8, 15),
        aula: 'Pabellón Inicial - Aula 01',
        usuarioAcceso: 'est.est202602',
        claveTemporal: 'Estudiante2026!',
      ),
      StudentEnrollment(
        id: 'enr-003',
        colegioId: defaultColegio,
        estudianteId: 'f0000000-0000-0000-0000-000000000003',
        estudianteNombre: 'Lucas Ramírez Méndez',
        matricula: 'EST-2026-03',
        cursoId: 'cur-002',
        cursoNombre: '1ro de Primaria',
        seccionId: 'sec-002',
        seccionNombre: 'Sección A',
        anioEscolar: '2025-2026',
        fechaAsignacion: DateTime(2025, 8, 18),
        aula: 'Edificio Central - Aula 101',
        usuarioAcceso: 'est.est202603',
        claveTemporal: 'Estudiante2026!',
      ),
    ]);

    // 7. Eventos Académicos Programados en Aulas (Issue #21 - Caso 4)
    _classroomEvents.addAll([
      ClassroomEvent(
        id: 'evt-001',
        colegioId: defaultColegio,
        cursoId: 'cur-002',
        seccionId: 'sec-002',
        titulo: 'Examen Parcial de Matemáticas',
        tipo: 'Examen',
        fecha: DateTime.now().add(const Duration(days: 3)),
        profesorNombre: 'Lic. Rosaura Peña',
        materiaNombre: 'Matemáticas',
        descripcion: 'Evaluación escrita sobre números naturales, sumas y restas con reagrupación.',
      ),
      ClassroomEvent(
        id: 'evt-002',
        colegioId: defaultColegio,
        cursoId: 'cur-002',
        seccionId: 'sec-002',
        titulo: 'Feria de Ciencias: El Ciclo del Agua',
        tipo: 'Proyecto',
        fecha: DateTime.now().add(const Duration(days: 7)),
        profesorNombre: 'Dra. Elena Vásquez',
        materiaNombre: 'Ciencias de la Naturaleza',
        descripcion: 'Presentación interactiva de maquetas y experimentos en equipos de 4 alumnos.',
      ),
      ClassroomEvent(
        id: 'evt-003',
        colegioId: defaultColegio,
        cursoId: 'cur-002',
        seccionId: 'sec-002',
        titulo: 'Lectura Dirigida & Dramatización',
        tipo: 'Actividad',
        fecha: DateTime.now().add(const Duration(days: 10)),
        profesorNombre: 'Lic. Marcos Almonte',
        materiaNombre: 'Lengua Española',
        descripcion: 'Taller de expresión oral y comprensión lectora basado en cuentos caribeños.',
      ),
    ]);
  }

  // ==========================================
  // PERSISTENCIA LOCAL (SharedPreferences)
  // ==========================================
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final coursesRaw = prefs.getString(_prefKeyCourses);
      if (coursesRaw != null) {
        final list = (jsonDecode(coursesRaw) as List<dynamic>)
            .map((e) => AcademicCourse.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _courses.clear();
          _courses.addAll(list);
        }
      }

      final sectionsRaw = prefs.getString(_prefKeySections);
      if (sectionsRaw != null) {
        final list = (jsonDecode(sectionsRaw) as List<dynamic>)
            .map((e) => AcademicSection.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _sections.clear();
          _sections.addAll(list);
        }
      }

      final subjectsRaw = prefs.getString(_prefKeySubjects);
      if (subjectsRaw != null) {
        final list = (jsonDecode(subjectsRaw) as List<dynamic>)
            .map((e) => AcademicSubject.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _subjects.clear();
          _subjects.addAll(list);
        }
      }

      final teachersRaw = prefs.getString(_prefKeyTeachers);
      if (teachersRaw != null) {
        final list = (jsonDecode(teachersRaw) as List<dynamic>)
            .map((e) => AcademicTeacher.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _teachers.clear();
          _teachers.addAll(list);
        }
      }

      final assignmentsRaw = prefs.getString(_prefKeyAssignments);
      if (assignmentsRaw != null) {
        final list = (jsonDecode(assignmentsRaw) as List<dynamic>)
            .map((e) => TeacherAcademicAssignment.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _teacherAssignments.clear();
          _teacherAssignments.addAll(list);
        }
      }

      final enrollmentsRaw = prefs.getString(_prefKeyEnrollments);
      if (enrollmentsRaw != null) {
        final list = (jsonDecode(enrollmentsRaw) as List<dynamic>)
            .map((e) => StudentEnrollment.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _enrollments.clear();
          _enrollments.addAll(list);
        }
      }

      final eventsRaw = prefs.getString(_prefKeyClassroomEvents);
      if (eventsRaw != null) {
        final list = (jsonDecode(eventsRaw) as List<dynamic>)
            .map((e) => ClassroomEvent.fromJson(e as Map<String, dynamic>))
            .toList();
        if (list.isNotEmpty) {
          _classroomEvents.clear();
          _classroomEvents.addAll(list);
        }
      }
    } catch (_) {}
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyCourses, jsonEncode(_courses.map((e) => e.toJson()).toList()));
      await prefs.setString(_prefKeySections, jsonEncode(_sections.map((e) => e.toJson()).toList()));
      await prefs.setString(_prefKeySubjects, jsonEncode(_subjects.map((e) => e.toJson()).toList()));
      await prefs.setString(_prefKeyTeachers, jsonEncode(_teachers.map((e) => e.toJson()).toList()));
      await prefs.setString(
          _prefKeyAssignments, jsonEncode(_teacherAssignments.map((e) => e.toJson()).toList()));
      await prefs.setString(
          _prefKeyEnrollments, jsonEncode(_enrollments.map((e) => e.toJson()).toList()));
      await prefs.setString(
          _prefKeyClassroomEvents, jsonEncode(_classroomEvents.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  // ==========================================
  // GESTIÓN DE CURSOS (Issue #20)
  // ==========================================
  Future<List<AcademicCourse>> getCourses({String? colegioId}) async {
    return _courses.where((c) {
      if (colegioId != null && colegioId.isNotEmpty && c.colegioId != colegioId) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.orden.compareTo(b.orden));
  }

  Future<AcademicCourse> createCourse({
    required String colegioId,
    required String nombre,
    required String nivel,
    required String anioEscolar,
    List<String> materiasIds = const [],
  }) async {
    final newCourse = AcademicCourse(
      id: 'cur-${DateTime.now().millisecondsSinceEpoch}',
      colegioId: colegioId,
      nombre: nombre,
      nivel: nivel,
      anioEscolar: anioEscolar,
      materiasIds: materiasIds,
      orden: _courses.length + 1,
    );
    _courses.add(newCourse);
    await _saveToStorage();
    return newCourse;
  }

  Future<AcademicCourse?> updateCourse(AcademicCourse course) async {
    final idx = _courses.indexWhere((c) => c.id == course.id);
    if (idx == -1) return null;
    _courses[idx] = course;
    await _saveToStorage();
    return course;
  }

  Future<bool> deleteCourse(String courseId) async {
    _courses.removeWhere((c) => c.id == courseId);
    _sections.removeWhere((s) => s.cursoId == courseId);
    await _saveToStorage();
    return true;
  }

  // ==========================================
  // GESTIÓN DE SECCIONES (Issue #20)
  // ==========================================
  Future<List<AcademicSection>> getSections({String? colegioId, String? cursoId}) async {
    return _sections.where((s) {
      if (colegioId != null && colegioId.isNotEmpty && s.colegioId != colegioId) return false;
      if (cursoId != null && cursoId.isNotEmpty && s.cursoId != cursoId) return false;
      return true;
    }).toList();
  }

  Future<AcademicSection> createSection({
    required String colegioId,
    required String cursoId,
    required String cursoNombre,
    required String nombre,
    required String anioEscolar,
    int capacidadEstudiantes = 30,
    String? aula,
    String? profesorTitularId,
    String? profesorTitularNombre,
  }) async {
    final newSection = AcademicSection(
      id: 'sec-${DateTime.now().millisecondsSinceEpoch}',
      colegioId: colegioId,
      cursoId: cursoId,
      cursoNombre: cursoNombre,
      nombre: nombre,
      anioEscolar: anioEscolar,
      capacidadEstudiantes: capacidadEstudiantes,
      aula: aula,
      profesorTitularId: profesorTitularId,
      profesorTitularNombre: profesorTitularNombre,
      activa: true,
    );
    _sections.add(newSection);
    await _saveToStorage();
    return newSection;
  }

  Future<AcademicSection?> updateSection(AcademicSection section) async {
    final idx = _sections.indexWhere((s) => s.id == section.id);
    if (idx == -1) return null;
    _sections[idx] = section;
    await _saveToStorage();
    return section;
  }

  Future<bool> deleteSection(String sectionId) async {
    _sections.removeWhere((s) => s.id == sectionId);
    _teacherAssignments.removeWhere((a) => a.seccionId == sectionId);
    await _saveToStorage();
    return true;
  }

  // ==========================================
  // GESTIÓN DE MATERIAS (Issue #20)
  // ==========================================
  Future<List<AcademicSubject>> getSubjects({String? colegioId, String? cursoId}) async {
    return _subjects.where((m) {
      if (colegioId != null && colegioId.isNotEmpty && m.colegioId != colegioId) return false;
      if (cursoId != null && cursoId.isNotEmpty && !m.cursosIds.contains(cursoId)) return false;
      return true;
    }).toList();
  }

  Future<AcademicSubject> createSubject({
    required String colegioId,
    required String nombre,
    required String codigo,
    int horasSemanales = 4,
    String? descripcion,
    List<String> cursosIds = const [],
    String colorHex = '#1E3A8A',
  }) async {
    final newSubject = AcademicSubject(
      id: 'mat-${DateTime.now().millisecondsSinceEpoch}',
      colegioId: colegioId,
      nombre: nombre,
      codigo: codigo,
      horasSemanales: horasSemanales,
      descripcion: descripcion,
      cursosIds: cursosIds,
      colorHex: colorHex,
    );
    _subjects.add(newSubject);
    await _saveToStorage();
    return newSubject;
  }

  Future<AcademicSubject?> updateSubject(AcademicSubject subject) async {
    final idx = _subjects.indexWhere((s) => s.id == subject.id);
    if (idx == -1) return null;
    _subjects[idx] = subject;
    await _saveToStorage();
    return subject;
  }

  Future<bool> deleteSubject(String subjectId) async {
    _subjects.removeWhere((s) => s.id == subjectId);
    _teacherAssignments.removeWhere((a) => a.materiaId == subjectId);
    await _saveToStorage();
    return true;
  }

  // ==========================================
  // GESTIÓN DE PROFESORES (Issue #20)
  // ==========================================
  Future<List<AcademicTeacher>> getTeachers({String? colegioId, String? estado}) async {
    return _teachers.where((t) {
      if (colegioId != null && colegioId.isNotEmpty && t.colegioId != colegioId) return false;
      if (estado != null && estado.isNotEmpty && t.estado != estado) return false;
      return true;
    }).toList();
  }

  Future<AcademicTeacher> createTeacher({
    required String colegioId,
    required String nombreCompleto,
    required String cedula,
    required String email,
    required String telefono,
    required String especialidad,
    String estado = 'Activo',
    List<String> materiasQuePuedeImpartir = const [],
    String? fotoUrl,
    String estudios = 'Licenciatura en Educación',
    String? maestria,
    String experiencia = '5 años de experiencia docente',
    String referencias = 'Colegio San Judas Tadeo - Lic. Marcos Díaz (809-555-1234)',
    bool tieneCartaBuenaConducta = true,
    String? cartaBuenaConductaUrl,
    List<String> materiasQueImparte = const [],
    List<String> diasDisponibles = const ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes'],
    List<String> bloquesDisponibles = const ['08:00 - 09:30', '09:30 - 11:00', '11:15 - 12:45', '13:30 - 15:00'],
  }) async {
    // Generar credenciales de acceso automático (Issue #21 - Caso 6)
    final cleanParts = nombreCompleto
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'^(lic\.|dra\.|prof\.|tía|ing\.)\s*'), '')
        .split(' ')
        .where((s) => s.isNotEmpty)
        .toList();
    final userSuffix = cleanParts.length >= 2 ? '${cleanParts[0]}.${cleanParts[1]}' : cleanParts.first;
    final generatedUsername = 'prof.$userSuffix';
    const tempPassword = 'Docente2026!';

    final newTeacher = AcademicTeacher(
      id: 'tch-${DateTime.now().millisecondsSinceEpoch}',
      colegioId: colegioId,
      nombreCompleto: nombreCompleto,
      cedula: cedula,
      email: email,
      telefono: telefono,
      especialidad: especialidad,
      estado: estado,
      materiasQuePuedeImpartir: materiasQuePuedeImpartir,
      fotoUrl: fotoUrl,
      estudios: estudios,
      maestria: maestria,
      experiencia: experiencia,
      referencias: referencias,
      tieneCartaBuenaConducta: tieneCartaBuenaConducta,
      cartaBuenaConductaUrl: cartaBuenaConductaUrl,
      materiasQueImparte: materiasQueImparte.isNotEmpty ? materiasQueImparte : materiasQuePuedeImpartir,
      calificacionDesempeno: 4.8,
      diasDisponibles: diasDisponibles,
      bloquesDisponibles: bloquesDisponibles,
      usuarioAcceso: generatedUsername,
      claveTemporal: tempPassword,
      debeCambiarClave: true,
      evaluacionesDirector: const [],
    );
    _teachers.add(newTeacher);
    await _saveToStorage();
    return newTeacher;
  }

  /// Evalúa el desempeño de un profesor por parte del Director (Issue #21 - Caso 5)
  Future<AcademicTeacher?> evaluateTeacher({
    required String teacherId,
    required double puntaje,
    required String comentario,
    required String directorNombre,
    String criterio = 'Desempeño Pedagógico General',
  }) async {
    final idx = _teachers.indexWhere((t) => t.id == teacherId);
    if (idx == -1) return null;

    final current = _teachers[idx];
    final newEval = TeacherEvaluationRecord(
      id: 'eval-${DateTime.now().millisecondsSinceEpoch}',
      fecha: DateTime.now(),
      directorNombre: directorNombre,
      puntaje: puntaje.clamp(1.0, 5.0),
      criterio: criterio,
      comentario: comentario,
    );

    final updatedEvaluations = [...current.evaluacionesDirector, newEval];
    final double promedio =
        updatedEvaluations.map((e) => e.puntaje).reduce((a, b) => a + b) / updatedEvaluations.length;

    final updatedTeacher = current.copyWith(
      calificacionDesempeno: double.parse(promedio.toStringAsFixed(1)),
      evaluacionesDirector: updatedEvaluations,
    );

    _teachers[idx] = updatedTeacher;
    await _saveToStorage();
    return updatedTeacher;
  }

  Future<AcademicTeacher?> updateTeacher(AcademicTeacher teacher) async {
    final idx = _teachers.indexWhere((t) => t.id == teacher.id);
    if (idx == -1) return null;
    _teachers[idx] = teacher;
    await _saveToStorage();
    return teacher;
  }

  Future<bool> deleteTeacher(String teacherId) async {
    _teachers.removeWhere((t) => t.id == teacherId);
    _teacherAssignments.removeWhere((a) => a.profesorId == teacherId);
    await _saveToStorage();
    return true;
  }

  // ==========================================
  // ASIGNACIÓN ACADÉMICA DE PROFESORES (Issue #20, Issue #21)
  // ==========================================
  Future<List<TeacherAcademicAssignment>> getTeacherAssignments({
    String? colegioId,
    String? profesorId,
    String? seccionId,
    String? materiaId,
  }) async {
    return _teacherAssignments.where((a) {
      if (colegioId != null && colegioId.isNotEmpty && a.colegioId != colegioId) return false;
      if (profesorId != null && profesorId.isNotEmpty && a.profesorId != profesorId) return false;
      if (seccionId != null && seccionId.isNotEmpty && a.seccionId != seccionId) return false;
      if (materiaId != null && materiaId.isNotEmpty && a.materiaId != materiaId) return false;
      return true;
    }).toList();
  }

  /// Verifica la disponibilidad horaria del docente (Issue #21 - Caso 1)
  String? checkTeacherAvailability({
    required String profesorId,
    required String diaSemana,
    required String bloqueHorario,
  }) {
    final prof = _teachers.firstWhere(
      (t) => t.id == profesorId,
      orElse: () => const AcademicTeacher(
        id: '',
        colegioId: '',
        nombreCompleto: '',
        cedula: '',
        email: '',
        telefono: '',
        especialidad: '',
      ),
    );

    if (prof.id.isEmpty) return null;

    // Verificar si el día coincide con los días disponibles
    final cleanDia = diaSemana.toLowerCase();
    final tieneDia = prof.diasDisponibles.any((d) => cleanDia.contains(d.toLowerCase()));
    if (!tieneDia && prof.diasDisponibles.isNotEmpty) {
      return 'El profesor ${prof.nombreCompleto} no tiene disponibilidad configurada para el día "$diaSemana". Días disponibles: ${prof.diasDisponibles.join(", ")}.';
    }

    // Verificar si el bloque coincide (con o sin AM/PM)
    final cleanBloque = bloqueHorario.replaceAll(RegExp(r'\s*(AM|PM|am|pm)'), '').trim();
    final tieneBloque = prof.bloquesDisponibles.any((b) {
      final cleanB = b.replaceAll(RegExp(r'\s*(AM|PM|am|pm)'), '').trim();
      return cleanB == cleanBloque || b == bloqueHorario;
    });
    if (!tieneBloque && prof.bloquesDisponibles.isNotEmpty) {
      return 'El profesor ${prof.nombreCompleto} no tiene disponibilidad para el bloque "$bloqueHorario". Bloques disponibles: ${prof.bloquesDisponibles.join(", ")}.';
    }

    return null;
  }

  /// Detecta si hay choque o colisión de horarios (Issue #21 - Caso 1)
  /// Retorna un mensaje con el conflicto o null si está despejado.
  String? checkScheduleCollision({
    required String profesorId,
    required String seccionId,
    String? diaSemana,
    String? bloqueHorario,
    String anioEscolar = '2025-2026',
    String? excludeAssignmentId,
  }) {
    if (diaSemana == null || diaSemana.trim().isEmpty || bloqueHorario == null || bloqueHorario.trim().isEmpty) {
      return null;
    }

    // 1. Choque del Profesor: ¿Ya tiene clase ese día y bloque en OTRA sección o curso?
    final conflictoProfesor = _teacherAssignments.firstWhere(
      (a) =>
          a.id != excludeAssignmentId &&
          a.profesorId == profesorId &&
          a.anioEscolar == anioEscolar &&
          a.diaSemana == diaSemana &&
          a.bloqueHorario == bloqueHorario,
      orElse: () => const TeacherAcademicAssignment(
        id: '',
        colegioId: '',
        profesorId: '',
        profesorNombre: '',
        materiaId: '',
        materiaNombre: '',
        cursoId: '',
        cursoNombre: '',
        seccionId: '',
        seccionNombre: '',
        anioEscolar: '',
      ),
    );

    if (conflictoProfesor.id.isNotEmpty) {
      return 'Conflicto de Horario: El profesor ${conflictoProfesor.profesorNombre} ya imparte "${conflictoProfesor.materiaNombre}" en ${conflictoProfesor.cursoNombre} (${conflictoProfesor.seccionNombre}) los $diaSemana en el bloque $bloqueHorario.';
    }

    // 2. Choque de la Sección: ¿Esta sección ya tiene OTRA materia asignada en ese mismo día y bloque?
    final conflictoSeccion = _teacherAssignments.firstWhere(
      (a) =>
          a.id != excludeAssignmentId &&
          a.seccionId == seccionId &&
          a.anioEscolar == anioEscolar &&
          a.diaSemana == diaSemana &&
          a.bloqueHorario == bloqueHorario,
      orElse: () => const TeacherAcademicAssignment(
        id: '',
        colegioId: '',
        profesorId: '',
        profesorNombre: '',
        materiaId: '',
        materiaNombre: '',
        cursoId: '',
        cursoNombre: '',
        seccionId: '',
        seccionNombre: '',
        anioEscolar: '',
      ),
    );

    if (conflictoSeccion.id.isNotEmpty) {
      return 'Conflicto de Horario: La sección "${conflictoSeccion.seccionNombre}" ya tiene asignada la materia "${conflictoSeccion.materiaNombre}" con el profesor ${conflictoSeccion.profesorNombre} los $diaSemana en el bloque $bloqueHorario.';
    }

    return null;
  }

  /// Asigna un profesor a una materia y sección específica con horario y disponibilidad validada.
  Future<TeacherAcademicAssignment> assignTeacherToSubjectAndSection({
    required String colegioId,
    required String profesorId,
    required String materiaId,
    required String cursoId,
    required String seccionId,
    required String anioEscolar,
    String? horarioSemanal,
    String? diaSemana,
    String? bloqueHorario,
    String? aula,
  }) async {
    // 1. Validar duplicado exacto
    final existe = _teacherAssignments.any((a) =>
        a.colegioId == colegioId &&
        a.seccionId == seccionId &&
        a.materiaId == materiaId &&
        a.profesorId == profesorId);

    if (existe) {
      throw Exception('Esta asignación académica ya está registrada para este profesor en la misma sección y materia.');
    }

    // 2. Validar disponibilidad del profesor y choques de horario si se asigna bloque (Issue #21 - Caso 1)
    if (diaSemana != null && diaSemana.trim().isNotEmpty && bloqueHorario != null && bloqueHorario.trim().isNotEmpty) {
      final disponibilidadError = checkTeacherAvailability(
        profesorId: profesorId,
        diaSemana: diaSemana,
        bloqueHorario: bloqueHorario,
      );
      if (disponibilidadError != null) {
        throw Exception(disponibilidadError);
      }

      final colisionError = checkScheduleCollision(
        profesorId: profesorId,
        seccionId: seccionId,
        diaSemana: diaSemana,
        bloqueHorario: bloqueHorario,
        anioEscolar: anioEscolar,
      );
      if (colisionError != null) {
        throw Exception(colisionError);
      }
    }

    // Buscar nombres descriptivos
    final prof = _teachers.firstWhere(
      (t) => t.id == profesorId,
      orElse: () => AcademicTeacher(
        id: profesorId,
        colegioId: colegioId,
        nombreCompleto: 'Profesor',
        cedula: '',
        email: '',
        telefono: '',
        especialidad: '',
      ),
    );

    final mat = _subjects.firstWhere(
      (m) => m.id == materiaId,
      orElse: () => AcademicSubject(
        id: materiaId,
        colegioId: colegioId,
        nombre: 'Materia',
        codigo: '',
      ),
    );

    final cur = _courses.firstWhere(
      (c) => c.id == cursoId,
      orElse: () => AcademicCourse(
        id: cursoId,
        colegioId: colegioId,
        nombre: 'Curso',
        nivel: '',
        anioEscolar: anioEscolar,
      ),
    );

    final sec = _sections.firstWhere(
      (s) => s.id == seccionId,
      orElse: () => AcademicSection(
        id: seccionId,
        colegioId: colegioId,
        cursoId: cursoId,
        cursoNombre: cur.nombre,
        nombre: 'Sección',
        anioEscolar: anioEscolar,
      ),
    );

    final computedHorario = horarioSemanal ?? '$diaSemana $bloqueHorario';

    final newAssignment = TeacherAcademicAssignment(
      id: 'asg-${DateTime.now().millisecondsSinceEpoch}',
      colegioId: colegioId,
      profesorId: profesorId,
      profesorNombre: prof.nombreCompleto,
      materiaId: materiaId,
      materiaNombre: mat.nombre,
      cursoId: cursoId,
      cursoNombre: cur.nombre,
      seccionId: seccionId,
      seccionNombre: sec.nombre,
      anioEscolar: anioEscolar,
      horarioSemanal: computedHorario,
      diaSemana: diaSemana,
      bloqueHorario: bloqueHorario,
      aula: aula ?? sec.aula,
    );

    _teacherAssignments.add(newAssignment);
    await _saveToStorage();
    return newAssignment;
  }

  Future<bool> removeTeacherAssignment(String assignmentId) async {
    _teacherAssignments.removeWhere((a) => a.id == assignmentId);
    await _saveToStorage();
    return true;
  }

  // ==========================================
  // EVENTOS ACADÉMICOS DE AULA (Issue #21 - Caso 4)
  // ==========================================
  Future<List<ClassroomEvent>> getClassroomEvents({
    required String seccionId,
    String? colegioId,
  }) async {
    return _classroomEvents.where((e) {
      if (colegioId != null && colegioId.isNotEmpty && e.colegioId != colegioId) return false;
      if (e.seccionId != seccionId) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
  }

  Future<ClassroomEvent> addClassroomEvent(ClassroomEvent event) async {
    _classroomEvents.add(event);
    await _saveToStorage();
    return event;
  }

  // ==========================================
  // ASIGNACIÓN Y TRASLADO DE ESTUDIANTES (Issue #20, Issue #21)
  // ==========================================
  Future<List<StudentEnrollment>> getEnrollments({
    String? colegioId,
    String? cursoId,
    String? seccionId,
    String? estudianteId,
  }) async {
    return _enrollments.where((e) {
      if (colegioId != null && colegioId.isNotEmpty && e.colegioId != colegioId) return false;
      if (cursoId != null && cursoId.isNotEmpty && e.cursoId != cursoId) return false;
      if (seccionId != null && seccionId.isNotEmpty && e.seccionId != seccionId) return false;
      if (estudianteId != null && estudianteId.isNotEmpty && e.estudianteId != estudianteId) return false;
      return true;
    }).toList();
  }

  Future<StudentEnrollment> enrollStudent({
    required String colegioId,
    required String estudianteId,
    required String estudianteNombre,
    required String matricula,
    required String cursoId,
    required String cursoNombre,
    required String seccionId,
    required String seccionNombre,
    required String anioEscolar,
    String? aula,
  }) async {
    // Buscar aula de la sección si no se pasó
    String resolvedAula = aula ?? '';
    if (resolvedAula.isEmpty) {
      final sec = _sections.firstWhere((s) => s.id == seccionId, orElse: () => const AcademicSection(
        id: '', colegioId: '', cursoId: '', cursoNombre: '', nombre: '', anioEscolar: '',
      ));
      resolvedAula = sec.aula ?? '';
    }

    final cleanMat = matricula.replaceAll('-', '').toLowerCase();
    final generatedUsername = 'est.$cleanMat';
    const tempPassword = 'Estudiante2026!';

    // Si ya existe matrícula activa en el mismo año escolar, actualizar
    final existingIndex = _enrollments.indexWhere(
        (e) => e.estudianteId == estudianteId && e.anioEscolar == anioEscolar && e.estado == 'Activo');

    if (existingIndex != -1) {
      final updated = _enrollments[existingIndex].copyWith(
        cursoId: cursoId,
        cursoNombre: cursoNombre,
        seccionId: seccionId,
        seccionNombre: seccionNombre,
        aula: resolvedAula,
        usuarioAcceso: generatedUsername,
        claveTemporal: tempPassword,
      );
      _enrollments[existingIndex] = updated;
      await _saveToStorage();
      return updated;
    }

    final newEnrollment = StudentEnrollment(
      id: 'enr-${DateTime.now().millisecondsSinceEpoch}',
      colegioId: colegioId,
      estudianteId: estudianteId,
      estudianteNombre: estudianteNombre,
      matricula: matricula,
      cursoId: cursoId,
      cursoNombre: cursoNombre,
      seccionId: seccionId,
      seccionNombre: seccionNombre,
      anioEscolar: anioEscolar,
      fechaAsignacion: DateTime.now(),
      aula: resolvedAula,
      usuarioAcceso: generatedUsername,
      claveTemporal: tempPassword,
    );

    _enrollments.add(newEnrollment);
    await _saveToStorage();
    return newEnrollment;
  }

  /// Traslada a un estudiante a una nueva sección dentro del mismo curso o centro,
  /// registrando la sección anterior, la nueva y el motivo en el historial de traslados.
  Future<StudentEnrollment> transferStudentSection({
    required String enrollmentId,
    required String nuevaSeccionId,
    required String nuevaSeccionNombre,
    required String motivo,
    String? usuarioResponsable,
  }) async {
    final idx = _enrollments.indexWhere((e) => e.id == enrollmentId);
    if (idx == -1) {
      throw Exception('Matrícula no encontrada para realizar el traslado.');
    }

    final current = _enrollments[idx];
    final transferRecord = StudentTransferRecord(
      fecha: DateTime.now(),
      seccionAnterior: current.seccionNombre,
      seccionNueva: nuevaSeccionNombre,
      motivo: motivo,
      usuarioResponsable: usuarioResponsable,
    );

    final updatedHistorial = List<StudentTransferRecord>.from(current.historialTraslados)..add(transferRecord);

    final updatedEnrollment = current.copyWith(
      seccionId: nuevaSeccionId,
      seccionNombre: nuevaSeccionNombre,
      historialTraslados: updatedHistorial,
    );

    _enrollments[idx] = updatedEnrollment;
    await _saveToStorage();
    return updatedEnrollment;
  }

  // ==========================================
  // PANEL DE CONTROL ACADÉMICO / MÉTRICAS (Issue #20)
  // ==========================================
  AcademicDashboardMetrics getAcademicDashboardMetrics({String? colegioId}) {
    final courses = _courses.where((c) => colegioId == null || c.colegioId == colegioId).toList();
    final sections = _sections.where((s) => colegioId == null || s.colegioId == colegioId).toList();
    final teachers = _teachers.where((t) => colegioId == null || t.colegioId == colegioId).toList();
    final subjects = _subjects.where((s) => colegioId == null || s.colegioId == colegioId).toList();
    final enrollments = _enrollments
        .where((e) => (colegioId == null || e.colegioId == colegioId) && e.estado == 'Activo')
        .toList();

    final Map<String, int> alumnosPorCurso = {};
    final Map<String, int> capacidadPorCurso = {};

    for (final c in courses) {
      alumnosPorCurso[c.nombre] = enrollments.where((e) => e.cursoId == c.id).length;
      final seccionesDelCurso = sections.where((s) => s.cursoId == c.id);
      capacidadPorCurso[c.nombre] =
          seccionesDelCurso.fold<int>(0, (sum, sec) => sum + sec.capacidadEstudiantes);
    }

    final double promedioAula = sections.isNotEmpty
        ? (enrollments.length / sections.length)
        : 0.0;

    return AcademicDashboardMetrics(
      totalCursos: courses.length,
      totalSecciones: sections.length,
      totalEstudiantesMatriculados: enrollments.length,
      totalProfesores: teachers.length,
      totalMaterias: subjects.length,
      promedioEstudiantesPorAula: double.parse(promedioAula.toStringAsFixed(1)),
      estudiantesPorCurso: alumnosPorCurso,
      capacidadPorCurso: capacidadPorCurso,
    );
  }

  // ==========================================
  // FILTRADO DE SEGURIDAD DOCENTE (Issue #20 - Regla 6)
  // ==========================================
  /// Verifica si un docente tiene asignada una materia y sección específicas
  bool canTeacherAccessAssignment({
    required String teacherId,
    required String seccionId,
    required String materiaId,
  }) {
    return _teacherAssignments.any(
      (a) => a.profesorId == teacherId && a.seccionId == seccionId && a.materiaId == materiaId,
    );
  }

  /// Retorna las asignaciones únicas para un profesor dado
  List<TeacherAcademicAssignment> getTeacherClasses(String teacherId) {
    return _teacherAssignments.where((a) => a.profesorId == teacherId).toList();
  }

  // ==========================================
  // REPORTES DE CALIFICACIONES (MINERD)
  // ==========================================
  Future<List<StudentGradeReport>> getReports({String? grado, String? seccion}) async {
    return _reports.where((r) {
      if (grado != null && grado.isNotEmpty && r.grado != grado) return false;
      if (seccion != null && seccion.isNotEmpty && r.seccion != seccion) return false;
      return true;
    }).toList();
  }

  Future<StudentGradeReport?> getReportForStudent(String studentId) async {
    try {
      return _reports.firstWhere((r) => r.studentId == studentId);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateSubjectGrade({
    required String reportId,
    required String materia,
    required int periodo, // 1, 2, 3 o 4
    required int nota,
  }) async {
    final reportIndex = _reports.indexWhere((r) => r.id == reportId);
    if (reportIndex == -1) return;

    final current = _reports[reportIndex];
    final updatedMaterias = current.materias.map((m) {
      if (m.materia != materia) return m;
      switch (periodo) {
        case 1:
          return m.copyWith(periodo1: nota);
        case 2:
          return m.copyWith(periodo2: nota);
        case 3:
          return m.copyWith(periodo3: nota);
        case 4:
          return m.copyWith(periodo4: nota);
        default:
          return m;
      }
    }).toList();

    _reports[reportIndex] = current.copyWith(materias: updatedMaterias);
  }

  Map<String, dynamic> getAcademicMetrics() {
    if (_reports.isEmpty) {
      return {
        'promedioGeneral': 0.0,
        'tasaAprobacion': 100.0,
        'cuadroHonorCount': 0,
        'reforzamientoCount': 0,
        'totalEvaluados': 0,
      };
    }

    double sumaPromedios = 0.0;
    int honorCount = 0;
    int reforzamientoCount = 0;

    for (final r in _reports) {
      final p = r.promedioGeneral;
      sumaPromedios += p;
      if (r.honorRoll) honorCount++;
      if (p < 70 && p > 0) reforzamientoCount++;
    }

    final promGeneral = sumaPromedios / _reports.length;
    final aprobados = _reports.where((r) => r.promedioGeneral >= 70).length;
    final tasaAprob = (aprobados / _reports.length) * 100.0;

    return {
      'promedioGeneral': promGeneral,
      'tasaAprobacion': tasaAprob,
      'cuadroHonorCount': honorCount,
      'reforzamientoCount': reforzamientoCount,
      'totalEvaluados': _reports.length,
    };
  }
}
