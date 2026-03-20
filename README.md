# FamilyWallet

Aplicacion movil de gestion financiera familiar compartida, construida con Flutter y Firebase.

## Funcionalidades

- **Autenticacion:** Registro e inicio de sesion con email/password o Google Sign-In.
- **Familias:** Crear o unirse a una familia con un codigo de invitacion de 6 caracteres.
- **Movimientos:** Registro de gastos e ingresos (compartidos o personales). Soporte para sueldos mensuales.
- **Dashboard:** Saldo total historico, termometro de presupuesto mensual y ultimos movimientos.
- **Historial:** Listado completo de movimientos con filtros.
- **Estadisticas:** Grafico de dona por categoria, comparacion mes vs. mes anterior y estado de deudas.
- **Metas de ahorro:** Seguimiento de objetivos financieros con barra de progreso.
- **Sueldos:** Registro del aporte mensual de cada miembro de la familia.
- **Suscripciones y Gastos Fijos:** Alta y seguimiento de gastos recurrentes con boton para descontar del mes actual.
- **Deudas:** Calculo automatico de deudas entre miembros segun gastos compartidos. Soporte para deudas manuales.
- **FinanceBot:** Asistente financiero con inteligencia artificial (Gemini) integrado.
- **Configuracion:** Modo oscuro/claro, abandono de familia y cierre de sesion.

## Stack Tecnologico

| Tecnologia         | Uso                                      |
|--------------------|------------------------------------------|
| Flutter            | Framework principal (iOS y Android)      |
| Firebase Auth      | Autenticacion de usuarios                |
| Cloud Firestore    | Base de datos en tiempo real             |
| Google Sign-In     | Inicio de sesion con Google              |
| Riverpod           | Manejo de estado                         |
| GoRouter           | Navegacion declarativa                   |
| fl_chart           | Graficos y visualizaciones               |
| Gemini AI          | FinanceBot via google_generative_ai      |

## Estructura del Proyecto

```
lib/
├── app_router.dart          # Definicion de rutas y logica de redireccion
├── main.dart                # Punto de entrada de la aplicacion
├── core/
│   ├── constants/           # Categorias de movimientos (colores, iconos)
│   ├── theme/               # AppTheme (colores, tipografia, tema oscuro/claro)
│   ├── utils/               # Formateadores de moneda, snackbars reutilizables
│   └── widgets/             # Widgets reutilizables (TermometroWidget, MovimientoTile)
├── models/                  # Modelos de datos (Movimiento, Familia, Miembro, etc.)
├── providers/               # Providers de Riverpod (estado global, streams)
├── screens/                 # Pantallas organizadas por feature
│   ├── onboarding/          # Welcome, Auth, FamiliaScreen
│   ├── home/                # Dashboard, MainScaffold (barra de navegacion)
│   ├── historial/           # Listado de movimientos
│   ├── estadisticas/        # Graficos y analisis
│   ├── metas/               # Metas de ahorro
│   ├── sueldos/             # Gestion de sueldos mensuales
│   ├── suscripciones/       # Gastos fijos y suscripciones
│   ├── deudas/              # Deudas entre miembros y manuales
│   ├── finance_bot/         # Chat con FinanceBot (Gemini)
│   ├── movimiento/          # Formulario de nuevo movimiento
│   └── configuracion/       # Ajustes de cuenta y familia
└── services/                # Logica de acceso a Firebase (Auth, Familia, Movimiento, etc.)
```

## Configuracion Inicial

1. Clonar el repositorio.
2. Crear un proyecto en [Firebase Console](https://console.firebase.google.com/) y habilitar **Authentication** (Email/Password y Google) y **Firestore**.
3. Descargar el archivo `google-services.json` y colocarlo en `android/app/`.
4. Copiar `.env.example` a `.env` y completar la clave de Gemini (opcional, requerido para FinanceBot):
   ```
   GEMINI_API_KEY=tu_clave_aqui
   ```
5. Ejecutar:
   ```bash
   flutter pub get
   flutter run
   ```

> **Nota:** Para Google Sign-In en Android, asegurate de registrar las huellas SHA-1 y SHA-256 de tu keystore en la configuracion de Android en Firebase Console.

## Licencia

Este proyecto es de uso personal/educativo.
