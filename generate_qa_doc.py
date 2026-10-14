# -*- coding: utf-8 -*-
import os
import subprocess
import shutil

html_content = """<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <title>EDUNEX - Manual Oficial de Pruebas y Certificación de Calidad (QA)</title>
  <style>
    @page {
      size: A4 portrait;
      margin: 14mm 14mm 14mm 14mm;
    }
    
    * {
      box-sizing: border-box;
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }

    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      color: #1e293b;
      line-height: 1.35;
      font-size: 9.5pt;
      margin: 0;
      padding: 0;
      background-color: #ffffff;
    }

    /* Portada / Cover Page */
    .cover-page {
      page-break-after: always;
      padding-top: 5px;
    }

    .cover-top {
      border-bottom: 4px solid #4f46e5;
      padding-bottom: 16px;
      margin-bottom: 18px;
    }

    .brand-logo {
      display: inline-block;
      background: linear-gradient(135deg, #4f46e5 0%, #312e81 100%);
      color: #ffffff;
      padding: 6px 16px;
      font-size: 20pt;
      font-weight: 900;
      letter-spacing: 2px;
      border-radius: 6px;
      margin-bottom: 10px;
    }

    .cover-title {
      font-size: 22pt;
      font-weight: 800;
      color: #0f172a;
      margin: 8px 0 4px 0;
      line-height: 1.2;
    }

    .cover-subtitle {
      font-size: 12pt;
      color: #475569;
      font-weight: 500;
      margin-top: 0;
      margin-bottom: 10px;
    }

    .badge-bar {
      display: flex;
      gap: 8px;
      margin-top: 12px;
    }

    .badge {
      display: inline-block;
      padding: 4px 10px;
      border-radius: 16px;
      font-size: 8pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }

    .badge-primary { background-color: #e0e7ff; color: #4338ca; }
    .badge-success { background-color: #d1fae5; color: #065f46; }
    .badge-warning { background-color: #fef3c7; color: #92400e; }
    .badge-info { background-color: #cffafe; color: #155e75; }

    .card-box {
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 8px;
      padding: 14px 16px;
      margin-bottom: 16px;
    }

    .card-box h3 {
      margin-top: 0;
      margin-bottom: 8px;
      color: #1e1b4b;
      font-size: 11pt;
      border-bottom: 2px solid #e2e8f0;
      padding-bottom: 5px;
    }

    .spec-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 8px;
      font-size: 9pt;
    }

    .spec-item strong {
      color: #0f172a;
      display: inline-block;
      width: 130px;
    }

    .cover-footer {
      border-top: 1px solid #cbd5e1;
      padding-top: 10px;
      margin-top: 20px;
      font-size: 8pt;
      color: #64748b;
      display: flex;
      justify-content: space-between;
    }

    /* Headings */
    h1 {
      font-size: 14pt;
      font-weight: 800;
      color: #1e1b4b;
      border-bottom: 2px solid #6366f1;
      padding-bottom: 4px;
      margin-top: 16px;
      margin-bottom: 10px;
      page-break-after: avoid;
    }

    h2 {
      font-size: 11pt;
      font-weight: 700;
      color: #334155;
      margin-top: 12px;
      margin-bottom: 5px;
      page-break-after: avoid;
    }

    p {
      margin: 0 0 6px 0;
    }

    .page-break {
      page-break-before: always;
    }

    /* Tables */
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 8px 0 12px 0;
      font-size: 8.5pt;
      page-break-inside: avoid;
    }

    th, td {
      border: 1px solid #cbd5e1;
      padding: 5px 8px;
      text-align: left;
      vertical-align: top;
    }

    th {
      background-color: #f1f5f9;
      color: #0f172a;
      font-weight: 700;
    }

    tr:nth-child(even) td {
      background-color: #f8fafc;
    }

    /* Callouts */
    .callout {
      border-left: 4px solid #4f46e5;
      background-color: #f5f3ff;
      padding: 10px 14px;
      border-radius: 0 6px 6px 0;
      margin: 10px 0;
      font-size: 9pt;
      page-break-inside: avoid;
    }

    .callout-success {
      border-left-color: #10b981;
      background-color: #ecfdf5;
    }

    .callout-warning {
      border-left-color: #f59e0b;
      background-color: #fffbeb;
    }

    .callout-title {
      font-weight: 700;
      color: #1e1b4b;
      margin-bottom: 4px;
    }

    /* Step boxes */
    .step-box {
      background: #ffffff;
      border: 1px solid #e2e8f0;
      border-radius: 6px;
      padding: 9px 12px;
      margin-bottom: 10px;
      page-break-inside: avoid;
    }

    .step-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      font-weight: 700;
      color: #1e293b;
      border-bottom: 1px dashed #cbd5e1;
      padding-bottom: 4px;
      margin-bottom: 5px;
    }

    ol, ul {
      margin: 3px 0;
      padding-left: 18px;
    }

    li {
      margin-bottom: 2px;
    }

    .role-badge {
      display: inline-block;
      font-size: 7.5pt;
      padding: 2px 7px;
      border-radius: 10px;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.3px;
    }

    .role-superadmin { background: #fee2e2; color: #991b1b; }
    .role-admin { background: #e0e7ff; color: #3730a3; }
    .role-parent { background: #dcfce7; color: #166534; }
    .role-student { background: #fef3c7; color: #854d0e; }

    code {
      font-family: ui-monospace, Menlo, Monaco, Consolas, monospace;
      background-color: #f1f5f9;
      color: #0f172a;
      padding: 1px 4px;
      border-radius: 3px;
      font-size: 8pt;
    }
  </style>
</head>
<body>

  <!-- ==================== PORTADA (PÁGINA 1) ==================== -->
  <div class="cover-page">
    <div class="cover-top">
      <div class="brand-logo">EDUNEX</div>
      <div class="cover-title">Protocolo de Certificación y Pruebas QA (UAT)</div>
      <div class="cover-subtitle">Manual Exhaustivo de Validación Funcional de Sistema Integral</div>
      <div class="badge-bar">
        <span class="badge badge-primary">Versión Staging v1.4.0</span>
        <span class="badge badge-success">32 / 32 Tests Aprobados</span>
        <span class="badge badge-warning">Listo para QA</span>
        <span class="badge badge-info">Multi-Rol & Multi-Tenant</span>
      </div>
    </div>

    <div class="card-box">
      <h3>Ficha Técnica del Entorno de Pruebas</h3>
      <div class="spec-grid">
        <div class="spec-item"><strong>Rama de Git:</strong> <code>staging</code></div>
        <div class="spec-item"><strong>Último Commit:</strong> <code>dbc3f7e</code></div>
        <div class="spec-item"><strong>Target / Plataforma:</strong> Flutter Web (Chrome / Edge / Safari / Mobile)</div>
        <div class="spec-item"><strong>Cobertura Automatizada:</strong> 100% Passing Unit & Widget Tests</div>
        <div class="spec-item"><strong>Moneda de Prueba:</strong> DOP (RD$) / USD ($)</div>
        <div class="spec-item"><strong>Normativa Educativa:</strong> MINERD (República Dominicana)</div>
      </div>
    </div>

    <div class="card-box">
      <h3>Credenciales de Acceso Rápido para Pruebas (Botones Demo en Login)</h3>
      <table style="margin: 0;">
        <thead>
          <tr>
            <th>Rol de Prueba</th>
            <th>Usuario Demo / Identificador</th>
            <th>Colegio Asociado</th>
            <th>Objetivo Principal de Prueba</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><span class="role-badge role-superadmin">Superadmin</span></td>
            <td><code>superadmin@edunex.com</code></td>
            <td>Panel SaaS Global</td>
            <td>Métricas globales, simulador SaaS y creación de colegios</td>
          </tr>
          <tr>
            <td><span class="role-badge role-admin">Administrador</span></td>
            <td><code>director@colegioejemplo.edu.do</code></td>
            <td>Colegio San Juan Bautista</td>
            <td>Cobranzas, aging, boletín de notas, asistencia y transporte</td>
          </tr>
          <tr>
            <td><span class="role-badge role-parent">Padre de Familia</span></td>
            <td><code>padre@demo.com</code></td>
            <td>Colegio San Juan Bautista</td>
            <td>Portal 10 módulos: boletín, pagos, firmas y consentimientos</td>
          </tr>
          <tr>
            <td><span class="role-badge role-student">Estudiante</span></td>
            <td><code>mateo.perez@estudiante.edunex.do</code></td>
            <td>Colegio San Juan Bautista</td>
            <td>Portal estudiantil simplificado y vista de horario/materias</td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="cover-footer">
      <span>EDUNEX Technologies Inc. &copy; 2026 - Documento Confidencial de Control de Calidad</span>
      <span>Generado el 14 de Octubre de 2026</span>
    </div>
  </div>

  <!-- ==================== INTRODUCCIÓN Y ARQUITECTURA (PÁGINA 2) ==================== -->
  <h1>1. Instrucciones de Ejecución para el Analista QA</h1>
  <p>Este manual describe <strong>cada módulo funcional construido y desplegado en EDUNEX</strong>. Su objetivo es brindar a los analistas de pruebas y aseguramiento de la calidad (QA) el paso a paso exacto para verificar el cumplimiento funcional y de negocio, sin requerir configuración manual previa de base de datos.</p>

  <div class="callout callout-success">
    <div class="callout-title">✓ Facilidad de Ejecución Inmediata</div>
    La pantalla de Login dispone de botones directos de <strong>Acceso Rápido</strong> para cada rol. Al hacer clic en cualquiera de ellos, el sistema conmuta automáticamente el perfil de autenticación, los permisos de navegación y los datos contextuales del colegio piloto sin necesidad de teclear contraseñas.
  </div>

  <h2>Cómo Levantar el Entorno Local de Pruebas</h2>
  <div class="step-box">
    <div class="step-header">
      <span>Opción A: Ejecución en Tiempo Real (Hot Reload)</span>
      <code>flutter run -d chrome</code>
    </div>
    <p>Abre una terminal en la raíz del proyecto y ejecuta el comando anterior. La aplicación abrirá automáticamente una ventana de Google Chrome conectada a la sesión interactiva.</p>
  </div>

  <div class="step-box">
    <div class="step-header">
      <span>Opción B: Servir la Compilación de Producción Web</span>
      <code>npx serve build/web -l 8080</code>
    </div>
    <p>Permite probar la versión final ya compilada y optimizada en <code>http://localhost:8080</code> con minificación y tree-shaking idénticos a los del entorno de despliegue final.</p>
  </div>

  <h2>Mapa General de Navegación del Sistema</h2>
  <table>
    <thead>
      <tr>
        <th>Módulo Funcional</th>
        <th>Ruta / Menú en MainShell</th>
        <th>Roles con Acceso</th>
        <th>Funcionalidad Crítica</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><strong>Onboarding & Login</strong></td>
        <td><code>/login</code></td>
        <td>Todos</td>
        <td>Casos 1, 2, 3 y 4 de creación de colegio y director</td>
      </tr>
      <tr>
        <td><strong>Master SaaS Panel</strong></td>
        <td>Menú Lateral: <em>Master SaaS</em></td>
        <td>Superadmin</td>
        <td>KPIs MRR, simulador de precios y metas MINERD</td>
      </tr>
      <tr>
        <td><strong>Gestión de Familias</strong></td>
        <td>Menú Lateral: <em>Familias & Admisiones</em></td>
        <td>Admin</td>
        <td>Creación de familias multi-hijo, dossier y cotización</td>
      </tr>
      <tr>
        <td><strong>Finanzas & Caja</strong></td>
        <td>Menú Lateral: <em>Finanzas & Pagos</em></td>
        <td>Admin</td>
        <td>Registro de cobros, recibos oficiales y arqueo</td>
      </tr>
      <tr>
        <td><strong>Corte & Cartera Vencida</strong></td>
        <td>Finanzas &gt; <em>Corte Mensual & Aging</em></td>
        <td>Admin</td>
        <td>Corte recurrente automático y reporte de mora (0-90+ d)</td>
      </tr>
      <tr>
        <td><strong>Gestión Académica</strong></td>
        <td>Menú Lateral: <em>Gestión Académica & Notas</em></td>
        <td>Admin / Docente</td>
        <td>Asentamiento P1-P4, cuadro de honor y escala MINERD</td>
      </tr>
      <tr>
        <td><strong>Asistencia Escolar</strong></td>
        <td>Menú Lateral: <em>Asistencia</em></td>
        <td>Admin / Docente / Padre</td>
        <td>Pase de lista diario y justificación de faltas</td>
      </tr>
      <tr>
        <td><strong>Transporte Seguro</strong></td>
        <td>Menú Lateral: <em>Transporte</em></td>
        <td>Admin / Chofer / Padre</td>
        <td>Rutas, abordaje en vivo y check-in de estudiantes</td>
      </tr>
      <tr>
        <td><strong>Circulares y Consentimientos</strong></td>
        <td>Menú Lateral: <em>Circulares</em></td>
        <td>Admin / Padre</td>
        <td>Publicación de comunicados y firma digital de padres</td>
      </tr>
      <tr>
        <td><strong>Eventos Institucionales</strong></td>
        <td>Menú Lateral: <em>Eventos</em></td>
        <td>Admin / Padre</td>
        <td>Calendario escolar e inscripción interactiva de alumnos</td>
      </tr>
      <tr>
        <td><strong>Portal para Padres</strong></td>
        <td>Menú Lateral: <em>Portal de Padres</em></td>
        <td>Padre / Tutor</td>
        <td>10 módulos integrados y descarga oficial de Boletín</td>
      </tr>
      <tr>
        <td><strong>Portal Estudiantil</strong></td>
        <td>Vista Principal de Estudiante</td>
        <td>Estudiante</td>
        <td>Consulta de materias, profesores y horario</td>
      </tr>
    </tbody>
  </table>

  <!-- ==================== CASOS DE PRUEBA 1 Y 2 (PÁGINA 3) ==================== -->
  <div class="page-break"></div>
  <h1>2. Matriz de Casos de Prueba (Paso a Paso)</h1>

  <h2>Módulo 1: Onboarding y Registro Multirrol (Casos 1 al 4)</h2>
  <div class="step-box">
    <div class="step-header">
      <span>Caso 1: Registro Completo (Nuevo Colegio + Nuevo Director)</span>
      <span class="role-badge role-superadmin">Onboarding</span>
    </div>
    <ol>
      <li>En la pantalla de Login, presiona el botón <strong>"Registrar Colegio o Director"</strong>.</li>
      <li>Verifica que el diálogo <code>CreateSchoolDialog</code> se abra mostrando la opción <em>"Caso 1: Nuevo Colegio + Nuevo Director"</em> seleccionada por defecto.</li>
      <li>Llena los campos requeridos: Nombre del Colegio (ej. <em>"Colegio Bilingüe Las Américas"</em>), RNC, Teléfono, Nombre del Director, Correo y Contraseña.</li>
      <li>Llena los datos del primer estudiante de prueba y confirma la cotización calculada automáticamente.</li>
      <li>Haz clic en <strong>"Crear Colegio y Activar Director"</strong>.</li>
      <li><strong>Resultado Esperado:</strong> El colegio se crea exitosamente, se añade a la base de datos de colegios y el usuario es redirigido al panel administrativo con el branding institucional.</li>
    </ol>
  </div>

  <div class="step-box">
    <div class="step-header">
      <span>Casos 2, 3 y 4: Variaciones de Onboarding</span>
      <span class="role-badge role-admin">Director</span>
    </div>
    <ol>
      <li><strong>Caso 2 (Colegio Existente + Nuevo Director):</strong> Selecciona la pestaña correspondiente, elige un colegio ya creado de la lista desplegable y asigna un nuevo director.</li>
      <li><strong>Caso 3 (Director Existente + Nuevo Colegio):</strong> Permite que un director previamente registrado cree una nueva sucursal o sede educativa.</li>
      <li><strong>Caso 4 (Invitación con Token Institucional):</strong> Ingresa un token de invitación pregenerado para vincularse de forma instantánea al colegio sin aprobación manual.</li>
    </ol>
  </div>

  <h2>Módulo 2: Panel SaaS Master (Superadmin) y Simulador MINERD</h2>
  <div class="step-box">
    <div class="step-header">
      <span>Validación del Modelo de Negocio y Métricas Financieras SaaS</span>
      <span class="role-badge role-superadmin">Superadmin</span>
    </div>
    <ol>
      <li>Inicia sesión con el botón <strong>"Acceso Rápido: Superadmin (SaaS)"</strong>.</li>
      <li>Verifica la visualización de los 4 KPIs superiores: <em>Colegios Activos, Alumnos Totales, MRR Consolidado y ARR Proyectado</em>.</li>
      <li>Haz clic en el botón superior <strong>"Modelo de Negocio & Tarifas"</strong> para abrir el diálogo <code>BusinessModelDialog</code>.</li>
      <li>Verifica que la tabla de planes muestre:
        <ul>
          <li><strong>Plan Esencial:</strong> $2.50 USD / alumno / mes.</li>
          <li><strong>Plan Crecimiento:</strong> $3.50 USD / alumno / mes (Recomendado).</li>
          <li><strong>Plan Excelencia:</strong> $4.90 USD / alumno / mes.</li>
        </ul>
      </li>
      <li>Interactúa con el slider o campo de simulación de alumnos y verifica que el MRR se recalcula dinámicamente en tiempo real.</li>
      <li>Verifica la sección de metas de penetración MINERD (Colegios privados objetivo en Santo Domingo, Santiago y zona este).</li>
    </ol>
  </div>

  <!-- ==================== CASOS DE PRUEBA 3 Y 4 (PÁGINA 4) ==================== -->
  <div class="page-break"></div>
  <h1>2. Matriz de Casos de Prueba (Continuación)</h1>

  <h2>Módulo 3: Gestión de Familias y Admisiones Multi-Hijo</h2>
  <div class="step-box">
    <div class="step-header">
      <span>Registro de Familia con Descuento por Hermanos y Persistencia</span>
      <span class="role-badge role-admin">Admin</span>
    </div>
    <ol>
      <li>Accede como Administrador Escolar y navega a la sección <strong>"Familias & Admisiones"</strong>.</li>
      <li>Verifica la lista de familias precargadas (ej. Familia Pérez González).</li>
      <li>Haz clic en <strong>"+ Nueva Familia"</strong> para abrir <code>CreateFamilyDialog</code>.</li>
      <li>Ingresa los apellidos familiares, datos del tutor (nombre, cédula, teléfono, email) y los datos del <strong>Estudiante 1</strong> (Nivel, Grado, Colegiatura).</li>
      <li>Haz clic en <strong>"+ Agregar Hermano / 2do Estudiante"</strong>. Verifica que el formulario despliegue los campos del segundo hijo.</li>
      <li>Revisa la tarjeta de <strong>Cotización Automática</strong>: debe reflejar el 10% de descuento automático en la colegiatura del segundo hijo.</li>
      <li>Guarda la familia. Verifica que aparezca de inmediato en la tabla y que <strong>no desaparezca</strong> al cerrar y reabrir sesión.</li>
    </ol>
  </div>

  <h2>Módulo 4: Finanzas, Cobros en Caja y Recibos Oficiales</h2>
  <div class="step-box">
    <div class="step-header">
      <span>Cobro en Caja, Generación de Recibo y Balance Familiar</span>
      <span class="role-badge role-admin">Admin</span>
    </div>
    <ol>
      <li>Navega a <strong>"Finanzas & Pagos"</strong>.</li>
      <li>Verifica las tarjetas de resumen: <em>Total Recaudado este Mes, Pagos Registrados, Saldo Pendiente y Tasa de Cobranza</em>.</li>
      <li>Haz clic en <strong>"Registrar Cobro"</strong>.</li>
      <li>Selecciona la familia (ej. <em>Familia Pérez González</em>), el estudiante asociado y el concepto de pago (Colegiatura, Matrícula o Transporte).</li>
      <li>Ingresa el monto cobrado (ej. RD$ 14,500.00) y el método (Efectivo, Tarjeta de Crédito o Transferencia Bancaria).</li>
      <li>Confirma la transacción. Verifica que se genere el <strong>Recibo Oficial con número correlativo único</strong> y que el saldo pendiente de la familia disminuya automáticamente.</li>
    </ol>
  </div>

  <!-- ==================== CASOS DE PRUEBA 5 Y 6 (PÁGINA 5) ==================== -->
  <div class="page-break"></div>
  <h1>2. Matriz de Casos de Prueba (Continuación)</h1>

  <h2>Módulo 5: Automatización de Facturación Recurrente y Aging de Deuda</h2>
  <div class="step-box">
    <div class="step-header">
      <span>Ejecución del Corte Mensual y Reporte de Antigüedad de Cartera (Mora)</span>
      <span class="role-badge role-admin">Admin</span>
    </div>
    <ol>
      <li>En <strong>"Finanzas & Pagos"</strong>, haz clic en el botón de acción principal <strong>"Corte Mensual Recurrente"</strong>.</li>
      <li>Revisa el diálogo modal <code>MonthlyBillingDialog</code>: debe mostrar la previsualización del corte (total de colegiaturas a generar + servicios extracurriculares activos como cuido y transporte).</li>
      <li>Presiona <strong>"Confirmar y Ejecutar Facturación"</strong>. Verifica el mensaje de éxito indicando la cantidad de cargos generados.</li>
      <li>Cambia a la pestaña <strong>"Reporte de Antigüedad de Cartera (Aging & Mora)"</strong>.</li>
      <li>Verifica las 4 tarjetas de riesgo:
        <ul>
          <li><strong>Al Día (0 - 30 días):</strong> Familias con facturación reciente.</li>
          <li><strong>Riesgo Leve (31 - 60 días):</strong> 1 cuota vencida.</li>
          <li><strong>Riesgo Moderado (61 - 90 días):</strong> 2 cuotas vencidas.</li>
          <li><strong>Riesgo Crítico (&gt; 90 días):</strong> Cartera en mora grave.</li>
        </ul>
      </li>
      <li>Prueba el botón <strong>"Recordatorio WhatsApp"</strong> de una familia morosa y verifica el diálogo de envío con mensaje preformateado.</li>
    </ol>
  </div>

  <h2>Módulo 6: Récord Académico y Boletín Digital MINERD</h2>
  <div class="step-box">
    <div class="step-header">
      <span>Asentamiento de Calificaciones (Admin) y Visualización Oficial (Padres)</span>
      <span class="role-badge role-admin">Admin</span>
      <span class="role-badge role-parent">Padres</span>
    </div>
    <ol>
      <li><strong>Como Administrador:</strong> Entra a <strong>"Gestión Académica & Notas"</strong>.</li>
      <li>Revisa los KPIs: <em>Promedio General (ej. 89.4/100), Tasa de Aprobación, Estudiantes en Cuadro de Honor y En Reforzamiento</em>.</li>
      <li>Filtra por Grado (ej. <em>1ro Primaria</em>). Haz clic en el botón <strong>"Asentar / Editar Notas"</strong> en el alumno <em>Mateo Pérez</em>.</li>
      <li>Modifica la calificación del período P3 en Matemáticas (ej. cambiar a 95). Modifica la nota de conducta y las observaciones del maestro.</li>
      <li>Presiona <strong>"Guardar Calificaciones"</strong>. Verifica que el promedio ponderado se actualice al instante.</li>
      <li><strong>Como Padre de Familia:</strong> Conmuta al usuario Padre en el Login. Entra a <strong>"Portal de Padres"</strong> y pulsa <strong>"Boletín de Notas"</strong>.</li>
      <li>Verifica que el boletín oficial cargue el membrete del colegio acreditado por el MINERD, el selector de hijo, las materias con notas P1 a P4, la nota de conducta, las observaciones del docente y el botón <strong>"Descargar Boletín (PDF)"</strong>.</li>
    </ol>
  </div>

  <!-- ==================== CASOS DE PRUEBA 7 Y 8 (PÁGINA 6) ==================== -->
  <div class="page-break"></div>
  <h1>2. Matriz de Casos de Prueba (Continuación)</h1>

  <h2>Módulo 7: Asistencia y Justificaciones</h2>
  <div class="step-box">
    <div class="step-header">
      <span>Pase de Lista Diario y Justificación de Ausencias con Motivo Médico</span>
      <span class="role-badge role-admin">Admin</span>
      <span class="role-badge role-parent">Padres</span>
    </div>
    <ol>
      <li><strong>Como Administrador:</strong> Accede a <strong>"Asistencia"</strong>. Selecciona la fecha de hoy y el curso <em>1ro Primaria</em>.</li>
      <li>Cambia el estatus de un alumno de <em>Presente</em> a <em>Ausente</em> o <em>Tardanza</em> y verifica que la barra de porcentaje de asistencia del día se recalcule de inmediato.</li>
      <li><strong>Como Padre de Familia:</strong> En el Portal de Padres, ingresa al módulo de <strong>Asistencia</strong>.</li>
      <li>Revisa el historial de faltas de Mateo Pérez. Haz clic en <strong>"Justificar Falta"</strong>.</li>
      <li>Selecciona el motivo (ej. <em>Cita Médica Pediatra</em>), escribe una breve nota explicativa y envía la solicitud.</li>
      <li>Verifica que el estado de la ausencia cambie a <strong>"Justificada (En Revisión)"</strong>.</li>
    </ol>
  </div>

  <h2>Módulo 8: Rutas y Abordaje de Transporte Escolar Seguro</h2>
  <div class="step-box">
    <div class="step-header">
      <span>Monitoreo de Unidades, Rutas y Check-in en Tiempo Real</span>
      <span class="role-badge role-admin">Admin</span>
      <span class="role-badge role-parent">Padres</span>
    </div>
    <ol>
      <li><strong>Como Administrador:</strong> Accede a <strong>"Transporte"</strong>.</li>
      <li>Verifica las rutas disponibles (<em>Ruta 1 Norte - Autobús #04</em>, <em>Ruta 2 Sur</em>).</li>
      <li>Revisa la lista de pasajeros y el conductor asignado (Teléfono, Placa y Licencia).</li>
      <li>Haz clic en el botón de abordaje de un alumno para conmutar su estatus entre: <em>Esperando -&gt; Abordado en Autobús -&gt; Entregado en Colegio / Hogar</em>.</li>
      <li><strong>Como Padre de Familia:</strong> En el Portal de Padres, accede a <strong>"Transporte"</strong> y verifica que el estado de abordaje de tu hijo coincida exactamente en tiempo real.</li>
    </ol>
  </div>

  <!-- ==================== CASOS DE PRUEBA 9, 10, 11 Y 12 (PÁGINA 7) ==================== -->
  <div class="page-break"></div>
  <h1>2. Matriz de Casos de Prueba (Continuación)</h1>

  <h2>Módulo 9: Circulares y Firma Digital de Consentimientos</h2>
  <div class="step-box">
    <div class="step-header">
      <span>Publicación de Comunicados y Firma Electrónica con Trazabilidad</span>
      <span class="role-badge role-admin">Admin</span>
      <span class="role-badge role-parent">Padres</span>
    </div>
    <ol>
      <li><strong>Como Administrador:</strong> Accede a <strong>"Circulares"</strong>.</li>
      <li>Verifica los comunicados publicados y la métrica de <em>% de Familias que han Firmado</em>.</li>
      <li>Haz clic en <strong>"Nueva Circular"</strong>, escribe el título (ej. <em>"Excursión Botánica 2026"</em>), selecciona los grados destinatarios y activa el interruptor <strong>"Requiere Firma Digital de Autorización"</strong>.</li>
      <li><strong>Como Padre de Familia:</strong> Abre el módulo de <strong>Circulares</strong> en el Portal de Padres.</li>
      <li>Localiza la circular con etiqueta <em>"Firma Pendiente"</em>. Ábrela y presiona <strong>"Firmar Autorización"</strong>.</li>
      <li>Escribe el nombre del tutor legal, marca la casilla de consentimiento y pulsa <strong>"Confirmar Firma Electrónica"</strong>.</li>
      <li>Verifica que el badge cambie a <strong>"Firmado Digitalmente"</strong> con fecha y hora exacta.</li>
    </ol>
  </div>

  <h2>Módulo 10: Eventos Escolares e Inscripción de Alumnos</h2>
  <div class="step-box">
    <div class="step-header">
      <span>Catálogo de Actividades e Inscripción Interactiva</span>
      <span class="role-badge role-admin">Admin</span>
      <span class="role-badge role-parent">Padres</span>
    </div>
    <ol>
      <li><strong>Como Administrador:</strong> Abre <strong>"Eventos"</strong>, revisa el calendario y crea una nueva actividad con cupos y fecha límite.</li>
      <li><strong>Como Padre de Familia:</strong> Entra a <strong>"Eventos Escolares"</strong> en el Portal de Padres.</li>
      <li>Visualiza el catálogo de actividades (ej. <em>Feria de Ciencias, Torneo de Fútbol, Campamento</em>).</li>
      <li>Haz clic en <strong>"Inscribir Hijo"</strong>, selecciona cuál de los hijos asistirá y confirma la inscripción.</li>
      <li>Verifica que el cupo disminuya y el alumno quede formalmente registrado en la lista de participantes.</li>
    </ol>
  </div>

  <h2>Módulos 11 y 12: Portal de Padres y Portal Estudiantil</h2>
  <div class="step-box">
    <div class="step-header">
      <span>Autoservicio Familiar y Vista de Estudiantes</span>
      <span class="role-badge role-parent">Padres</span>
      <span class="role-badge role-student">Alumnos</span>
    </div>
    <ol>
      <li><strong>Portal de Padres (10 Módulos):</strong> Revisa la navegación entre hijos con el switch selector y verifica el acceso a: Pagos, Estado de Cuenta, Ficha Médica, Circulares, Asistencia, Transporte, Eventos, Horarios, Rutas y Boletín.</li>
      <li><strong>Portal Estudiantil:</strong> Inicia sesión con el botón <strong>"Acceso Rápido: Estudiante"</strong> y corrobora que Mateo Pérez solo tenga acceso a su horario, asignaturas y eventos, manteniendo protegida la información financiera y de cobros del hogar.</li>
    </ol>
  </div>

  <!-- ==================== FORMULARIO DE ACEPTACIÓN QA (PÁGINA 8) ==================== -->
  <div class="page-break"></div>
  <h1>3. Matriz de Aceptación QA (Formulario de Evaluación)</h1>
  <p>El analista de QA debe marcar con [✓] o [✗] cada criterio de aceptación y anotar cualquier discrepancia o bug identificado.</p>

  <table>
    <thead>
      <tr>
        <th style="width: 24%;">Módulo Funcional</th>
        <th style="width: 48%;">Criterio de Aceptación Esperado</th>
        <th style="width: 14%;">Resultado</th>
        <th style="width: 14%;">Tester</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td><strong>1. Login & Roles</strong></td>
        <td>Conmutación fluida entre Superadmin, Director, Padre y Alumno sin deslogueos erráticos.</td>
        <td>[ ] Pasa &nbsp; [ ] Falla</td>
        <td></td>
      </tr>
      <tr>
        <td><strong>2. Onboarding Casos 1-4</strong></td>
        <td>Creación de colegio y director con validaciones de campos obligatorios y cálculo de cotización.</td>
        <td>[ ] Pasa &nbsp; [ ] Falla</td>
        <td></td>
      </tr>
      <tr>
        <td><strong>3. Panel SaaS Master</strong></td>
        <td>Visualización de MRR/ARR global y simulador interactivo de tarifas según tiers $2.50 / $3.50 / $4.90.</td>
        <td>[ ] Pasa &nbsp; [ ] Falla</td>
        <td></td>
      </tr>
      <tr>
        <td><strong>4. Familias Multi-Hijo</strong></td>
        <td>Formulario permite añadir segundo hermano con 10% de descuento automático en cotización.</td>
        <td>[ ] Pasa &nbsp; [ ] Falla</td>
        <td></td>
      </tr>
      <tr>
        <td><strong>5. Persistencia de Datos</strong></td>
        <td>Las familias y pagos creados durante la sesión no desaparecen al cambiar de pantalla.</td>
        <td>[ ] Pasa &nbsp; [ ] Falla</td>
        <td></td>
      </tr>
      <tr>
        <td><strong>6. Cobranza en Caja</strong></td>
        <td>Generación de recibo oficial con numeración correlativa y rebaja inmediata del balance adeudado.</td>
        <td>[ ] Pasa &nbsp; [ ] Falla</td>
        <td></td>
      </tr>
      <tr>
        <td><strong>7. Facturación Recurrente</strong></td>
        <td>El botón "Corte Mensual Recurrente" emite cargos consolidados de colegiatura y servicios activos.</td>
        <td>[ ] Pasa &nbsp; [ ] Falla</td>
        <td></td>
      </tr>
      <tr>
        <td><strong>8. Aging de Cartera (Mora)</strong></td>
        <td>Clasificación exacta de morosidad en 4 tramos (0-30d, 31-60d, 61-90d, &gt;90d) con aviso WhatsApp.</td>
        <td>[ ] Pasa &nbsp; [ ] Falla</td>
        <td></td>
      </tr>
      <tr>
        <td><strong>9. Calificaciones Admin</strong></td>
        <td>Edición de períodos P1-P4, notas cualitativas, promedio automático y cálculo de Cuadro de Honor.</td>
        <td>[ ] Pasa &nbsp; [ ] Falla</td>
        <td></td>
      </tr>
      <tr>
        <td><strong>10. Boletín para Padres</strong></td>
        <td>Encabezado formal del colegio MINERD, notas por materia, conducta, observaciones y botón PDF.</td>
        <td>[ ] Pasa &nbsp; [ ] Falla</td>
        <td></td>
      </tr>
      <tr>
        <td><strong>11. Pase de Lista</strong></td>
        <td>Registro de Asistencia/Falta/Tardanza y actualización del indicador porcentual diario del aula.</td>
        <td>[ ] Pasa &nbsp; [ ] Falla</td>
        <td></td>
      </tr>
      <tr>
        <td><strong>12. Justificaciones</strong></td>
        <td>El padre puede emitir justificación con motivo médico/familiar y el colegio la visualiza.</td>
        <td>[ ] Pasa &nbsp; [ ] Falla</td>
        <td></td>
      </tr>
      <tr>
        <td><strong>13. Transporte Escolar</strong></td>
        <td>Check-in interactivo de abordaje que sincroniza en tiempo real con la app de los padres.</td>
        <td>[ ] Pasa &nbsp; [ ] Falla</td>
        <td></td>
      </tr>
      <tr>
        <td><strong>14. Circulares y Firmas</strong></td>
        <td>Publicación de avisos con firma requerida y modal de aceptación digital de consentimientos.</td>
        <td>[ ] Pasa &nbsp; [ ] Falla</td>
        <td></td>
      </tr>
      <tr>
        <td><strong>15. Inscripción a Eventos</strong></td>
        <td>Catálogo de actividades permite inscripción por hijo controlando cupos disponibles.</td>
        <td>[ ] Pasa &nbsp; [ ] Falla</td>
        <td></td>
      </tr>
      <tr>
        <td><strong>16. Portal Estudiantil</strong></td>
        <td>El estudiante visualiza su perfil, horario y profesores sin acceso a datos financieros familiares.</td>
        <td>[ ] Pasa &nbsp; [ ] Falla</td>
        <td></td>
      </tr>
    </tbody>
  </table>

  <!-- ==================== REPORTE DE INCIDENCIAS Y FIRMAS (PÁGINA 9) ==================== -->
  <div class="page-break"></div>
  <h1>4. Protocolo de Reporte de Incidencias (Bugs)</h1>
  <p>Si durante el proceso de pruebas se detecta cualquier desviación respecto al comportamiento esperado, el analista debe registrarlo utilizando la siguiente estructura obligatoria para su rápida atención y resolución por parte del equipo de ingeniería.</p>

  <div class="callout callout-warning">
    <div class="callout-title">Plantilla Obligatoria de Reporte al Equipo de Desarrollo:</div>
    <ul>
      <li><strong>ID del Caso de Prueba:</strong> (Ej. Módulo 5 - Aging de Cartera)</li>
      <li><strong>Rol Utilizado:</strong> (Superadmin / Admin / Padre / Estudiante)</li>
      <li><strong>Dispositivo / Navegador:</strong> (Ej. Chrome Web 120 / Mac Safari / Android)</li>
      <li><strong>Pasos para Reproducir:</strong>
        <ol style="margin-top: 4px;">
          <li>Iniciar sesión con el rol correspondiente...</li>
          <li>Navegar a la pantalla...</li>
          <li>Ingresar el valor...</li>
          <li>Hacer clic en el botón...</li>
        </ol>
      </li>
      <li><strong>Resultado Obtenido:</strong> (Comportamiento erróneo, bloqueo de UI o excepción de consola)</li>
      <li><strong>Resultado Esperado:</strong> (Comportamiento correcto esperado según esta especificación)</li>
      <li><strong>Severidad:</strong> [ ] Bloqueante &nbsp; [ ] Alta &nbsp; [ ] Media &nbsp; [ ] Menor</li>
      <li><strong>Evidencia Gráfica:</strong> (Adjuntar captura de pantalla, grabación o logs de consola)</li>
    </ul>
  </div>

  <h2>Cierre y Aprobación de Certificación de Calidad (UAT)</h2>
  <p>Al concluir satisfactoriamente el 100% de los casos de prueba de este protocolo, el responsable de QA y el líder técnico firman la conformidad para el pase a producción.</p>

  <div style="margin-top: 40px; border-top: 2px solid #cbd5e1; padding-top: 15px; display: grid; grid-template-columns: 1fr 1fr; gap: 40px; font-size: 9pt; color: #334155;">
    <div>
      <p><strong>Analista Responsable de QA:</strong></p>
      <div style="border-bottom: 1px solid #94a3b8; height: 35px; margin-bottom: 5px;"></div>
      <p>Nombre: ____________________________________</p>
      <p>Fecha: ______ / ______ / 2026</p>
      <p>Dictamen: [ ] Aprobado para Producción &nbsp; [ ] Rechazado</p>
    </div>
    <div>
      <p><strong>Líder Técnico / Product Owner:</strong></p>
      <div style="border-bottom: 1px solid #94a3b8; height: 35px; margin-bottom: 5px;"></div>
      <p>Nombre: ____________________________________</p>
      <p>Fecha: ______ / ______ / 2026</p>
      <p>Firma de Recepción: _______________________</p>
    </div>
  </div>

</body>
</html>
"""

output_html = "/tmp/edunex_qa_manual.html"
output_pdf_docs = os.path.abspath("docs/EDUNEX_Manual_QA_Pruebas_Staging.pdf")
output_pdf_root = os.path.abspath("EDUNEX_Manual_QA_Pruebas_Staging.pdf")

with open(output_html, "w", encoding="utf-8") as f:
    f.write(html_content)

chrome_cmd = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "--headless=new",
    "--disable-gpu",
    "--user-data-dir=/tmp/chrome_qa_export",
    "--no-pdf-header-footer",
    f"--print-to-pdf={output_pdf_docs}",
    f"file://{output_html}"
]

res = subprocess.run(chrome_cmd, capture_output=True, text=True)
if res.returncode == 0 and os.path.exists(output_pdf_docs):
    shutil.copyfile(output_pdf_docs, output_pdf_root)
    size_kb = os.path.getsize(output_pdf_docs) / 1024
    print(f"¡PDF final generado con éxito!\n- Docs: {output_pdf_docs} ({size_kb:.1f} KB)\n- Root: {output_pdf_root} ({size_kb:.1f} KB)")
else:
    print(f"Error generando PDF: returncode={res.returncode}")
