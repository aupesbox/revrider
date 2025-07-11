#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <TFT_eSPI.h>
#include <SPI.h>

// --- UUID Definitions (must match your Flutter app) ---
#define SERVICE_UUID        "12345678-1234-5678-1234-56789abcdef0"
#define CHAR_THROTTLE_UUID  "12345678-1234-5678-1234-56789abcdef1"
#define CHAR_CALIBRATE_UUID "12345678-1234-5678-1234-56789abcdef2"

// Create display instance
TFT_eSPI tft = TFT_eSPI();

// BLE Characteristic pointers
BLECharacteristic* throttleChar = nullptr;
BLECharacteristic* calibChar    = nullptr;

// Connection flag
volatile bool deviceConnected = false;
// Calibration flag
volatile bool needCalibration = false;

// Server callbacks to track connection status
class ServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) override {
    deviceConnected = true;
    // Display 'Connected' message
    tft.fillScreen(TFT_BLACK);
    tft.setTextSize(2);
    tft.setCursor(0, 0);
    tft.print("Connected");
  }
  void onDisconnect(BLEServer* pServer) override {
    deviceConnected = false;
    // Display 'Disconnected'
    tft.fillScreen(TFT_BLACK);
    tft.setTextSize(2);
    tft.setCursor(0, 0);
    tft.print("Disconnected");
  }
};

// Callback to handle writes to calibration characteristic
class CalibCallbacks : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pChar) override {
    String data = pChar->getValue();
    if (data.length() > 0 && data[0] == 0x01) {
      needCalibration = true;
      // Provide immediate on-screen feedback
      tft.fillScreen(TFT_BLACK);
      tft.setTextSize(2);
      tft.setCursor(0, 40);
      tft.print("Calibrated!");
    }
  }
};

void setup() {
  Serial.begin(115200);
  delay(500);

  // Initialize the display
  tft.init();
  tft.setRotation(1);
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  tft.setTextSize(2);
  tft.setCursor(0, 0);
  tft.println("Starting BLE");

  // Initialize BLE peripheral
  BLEDevice::init("aupesbox");
  BLEServer* server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallbacks());
  BLEService* service = server->createService(SERVICE_UUID);

  // Throttle % (Notify)
  throttleChar = service->createCharacteristic(
    CHAR_THROTTLE_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );
  throttleChar->addDescriptor(new BLE2902());

  // Calibration (Write)
  calibChar = service->createCharacteristic(
    CHAR_CALIBRATE_UUID,
    BLECharacteristic::PROPERTY_WRITE
  );
  calibChar->setCallbacks(new CalibCallbacks());

  service->start();

  // Start advertising
  BLEAdvertising* adv = server->getAdvertising();
  adv->addServiceUUID(SERVICE_UUID);
  adv->setScanResponse(true);
  adv->start();

  Serial.println("aupesbox peripheral up and advertising");
}

void loop() {
  // === Simulate throttle angle (0–255) ===
  static uint8_t angle = 0;
  static int8_t dir = 1;
  //angle += dir;
  // if (angle == 0 || angle == 255) dir = -dir;

  // === Notify central ===
  if (deviceConnected) {
    throttleChar->setValue(&angle, 1);
    throttleChar->notify();
    // Update on-screen throttle display
    tft.fillRect(0, 80, 240, 40, TFT_BLACK);  // clear area
    tft.setTextSize(3);
    tft.setCursor(0, 80);
    tft.printf("Thr: %d%%", angle);
    //angle -= dir;// remove this after imu
  }

  // === Handle calibration flag ===
  if (needCalibration) {
    needCalibration = false;
  }

  delay(50);  // ~20 Hz update rate
}
