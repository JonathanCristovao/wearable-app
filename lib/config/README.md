# 📝 Como Adicionar Novos Sensores

## 🎯 Resposta Rápida

**Para adicionar o 5º sensor (ou mais):**

1. Abra este arquivo: `lib/config/app_config.dart`
2. Encontre a linha:
   ```dart
   const int NUMBER_OF_SENSORS = 5;
   ```
3. Mude o número para quantos sensores você tem:
   ```dart
   const int NUMBER_OF_SENSORS = 10;  // Exemplo: 10 sensores
   ```
4. Salve e reinicie o app
5. **Pronto!** 🎉

## 📚 Documentação Completa

Para mais detalhes, consulte:

- **[REFACTORING_SUMMARY.md](../REFACTORING_SUMMARY.md)** - Resumo das mudanças
- **[DYNAMIC_SENSORS_GUIDE.md](../DYNAMIC_SENSORS_GUIDE.md)** - Guia completo de uso
- **[MIGRATION_GUIDE.md](../MIGRATION_GUIDE.md)** - Migração de código antigo

## ⚙️ Outras Configurações Neste Arquivo

```dart
// UUID da característica Bluetooth do sensor
const String SENSOR_DATA_CHARACTERISTIC_UUID = 'ffe1';

// Timeout de scan em segundos
const int BLUETOOTH_SCAN_TIMEOUT_SECONDS = 15;

// Timeout de conexão em segundos
const int BLUETOOTH_CONNECTION_TIMEOUT_SECONDS = 10;

// Intervalo de coleta de dados em milissegundos
const int DATA_COLLECTION_INTERVAL_MS = 100;
```

## 🎨 Personalizações

### Nomes dos Sensores
```dart
List<String> getDefaultSensorNames() {
  return [
    'Pulso Esquerdo',
    'Pulso Direito',
    'Tornozelo Esquerdo',
    'Tornozelo Direito',
    'Cintura',
    // Adicione mais conforme necessário
  ];
}
```

### Emojis/Ícones
```dart
String getSensorEmoji(int slotNumber) {
  const emojis = ['📱', '⌚', '👟', '🎒', '🧢'];
  return emojis[slotNumber - 1];
}
```

### Cores
```dart
int getSensorColor(int slotNumber) {
  const colors = [
    0xFF2196F3, // Blue
    0xFF4CAF50, // Green
    0xFFF44336, // Red
    0xFFFF9800, // Orange
    0xFF9C27B0, // Purple
  ];
  return colors[slotNumber - 1];
}
```

---

**Dúvidas?** Veja a documentação completa nos links acima! 📚
