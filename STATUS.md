# MultiConvert — Estado actual

**Última actualización:** 2026-05-19

---

## ✅ Completado

- Proyecto Xcode completo generado (`gen_xcodeproj.py`)
- 25+ archivos Swift — modelos, servicios, vistas, widget
- 42+ unit tests pasando (Swift Testing)
- Ícono 1024×1024 en Assets (`AppIcon.appiconset/icon.png`)
- Team ID configurado: `RK576HX8MX` (JUAN CARLOS RIBOT)
- Bundle ID: `com.jibaroenlaluna.multiconvert`
- Keypad rediseñado estilo Apple Calculator:
  - 3 columnas + píldora cero ancha (centrada)
  - Fondo negro puro
  - Botones dígitos: gris oscuro `#2A2A2C`
  - Botones utilidad (⌫, .): gris medio `#3A3A3C`
  - Botón C: ámbar
  - Íconos SF Symbols (`delete.backward.fill`)
  - Haptic feedback en cada toque
  - Sin columna vacía (4ª col eliminada)
  - Centrado horizontal con Spacer()
- **Monetización (StoreKit 2)**:
  - `PurchaseManager.swift` — `isPremium`, `isPurchasing`, `loadProducts()`, `purchase()`, `restorePurchases()`
  - Product ID: `com.jibaroenlaluna.multiconvert.removeads`
  - `isPremium` persiste en UserDefaults
  - `SettingsView` — sección "Premium" con botón compra y restaurar
  - `AdBannerView.swift` — stub 50pt (listo para Google Mobile Ads SDK)
  - Keypad tamaño diferenciado: free cap 64pt, premium cap 84pt
  - Banner de anuncio oculto para usuarios premium

---

## 🔧 Pendiente

### Instalar en iPhone (JCRibot Iphone — iPhone 13 Pro Max)
- **Problema:** el signing desde terminal no accede al keychain de Xcode
- **Solución:** hacerlo desde Xcode directamente
- **Pasos:**
  1. Abrir `MultiConvert.xcodeproj` en Xcode
  2. Target **MultiConvertWidget** → Signing & Capabilities → Team = JUAN CARLOS RIBOT
  3. Seleccionar **JCRibot Iphone** en el selector de destino (arriba)
  4. Presionar **⌘R**

### App Store — antes de subir
- Reemplazar `AdBannerView.swift` stub con Google Mobile Ads SDK real
- Test ad unit ID: `ca-app-pub-3940256099942544/2934735716`
- Llamar `GADMobileAds.sharedInstance().start()` en `MultiConvertApp.init()`
- Configurar producto IAP en App Store Connect: `com.jibaroenlaluna.multiconvert.removeads` ($1.99)

---

## 📱 APIs

| Servicio | URL | Límite |
|----------|-----|--------|
| Fiat | `api.frankfurter.app/latest` | Sin límite práctico |
| Crypto | `api.coingecko.com/v3/simple/price` | ~10-30 req/min |

---

## 📁 Archivos clave

| Archivo | Descripción |
|---------|-------------|
| `gen_xcodeproj.py` | Regenera el `.xcodeproj` (correr si se añaden archivos) |
| `MultiConvert/App/AppState.swift` | Estado global (@Observable) |
| `MultiConvert/Services/PurchaseManager.swift` | StoreKit 2 — compra única removeads |
| `MultiConvert/Views/NumericKeypad.swift` | Keypad centrado, 3 cols, tamaño por tier |
| `MultiConvert/Views/AdBannerView.swift` | Stub banner 50pt (reemplazar con SDK real) |
| `MultiConvert/Views/ContentView.swift` | Layout principal con banner condicional |
| `MultiConvert/Views/SettingsView.swift` | Sección Premium + restaurar compras |
| `MultiConvert/Services/ConversionEngine.swift` | Orquesta Fiat + Crypto |
| `MultiConvertWidget/MultiConvertWidget.swift` | Widget small + medium |
