#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BNO055.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <TFT_eSPI.h>

// ── BLE UUIDs ───────────────────────────────────────
#define SERVICE_UUID        "12345678-1234-5678-1234-56789abcdef0"
#define CHAR_THROTTLE_UUID  "12345678-1234-5678-1234-56789abcdef1"
#define CHAR_CALIBRATE_UUID "12345678-1234-5678-1234-56789abcdef2"

// ── Hardware Objects ────────────────────────────────
TFT_eSPI        tft = TFT_eSPI();
Adafruit_BNO055 bno = Adafruit_BNO055(55, 0x28);

// ── BLE Globals ─────────────────────────────────────
BLECharacteristic* throttleChar = nullptr;
BLECharacteristic* calibChar    = nullptr;
BLEAdvertising*    gAdv         = nullptr;   // global advertiser

volatile bool needCalibration   = false;
bool deviceConnected            = false;
bool oldDeviceConnected         = false;
float zeroOffset                = 0.0;

// ── Read Heading ────────────────────────────────────
float readHeading() {
    sensors_event_t evt;
    bno.getEvent(&evt);
    return evt.orientation.x; // 0–360
}

// ── BLE Callbacks ───────────────────────────────────
class ServerCB : public BLEServerCallbacks {
    void onConnect(BLEServer*) override {
        deviceConnected = true;
    }
    void onDisconnect(BLEServer*) override {
        deviceConnected = false;
        // 🔁 Restart advertising automatically
        if (gAdv) {
            gAdv->start();
            Serial.println("Restarting advertising...");
        }
    }
};

class CalibCB : public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic* chr) override {
        String v = chr->getValue();
        if (v.length() && v[0] == 0x01) {
            zeroOffset      = readHeading();
            needCalibration = true;
        }
    }
};

void setup() {
    Serial.begin(115200);
    delay(500);

    // TFT init
    tft.init();
    tft.setRotation(1);
    tft.fillScreen(TFT_BLACK);
    tft.setTextSize(2);
    tft.setTextColor(TFT_YELLOW, TFT_BLACK);
    tft.setCursor(0, 0);
    tft.print("Advertising...");

    // BNO055 init
    if (!bno.begin()) {
        Serial.println("BNO055 not found!");
        while (1) delay(10);
    }
    bno.setExtCrystalUse(true);

    // BLE init
    BLEDevice::init("aupesbox");
    BLEServer* server = BLEDevice::createServer();
    server->setCallbacks(new ServerCB());

    BLEService* svc = server->createService(SERVICE_UUID);

    throttleChar = svc->createCharacteristic(
            CHAR_THROTTLE_UUID, BLECharacteristic::PROPERTY_NOTIFY
    );
    throttleChar->addDescriptor(new BLE2902());

    calibChar = svc->createCharacteristic(
            CHAR_CALIBRATE_UUID, BLECharacteristic::PROPERTY_WRITE
    );
    calibChar->setCallbacks(new CalibCB());

    svc->start();

    // Global advertiser setup
    gAdv = server->getAdvertising();
    gAdv->addServiceUUID(SERVICE_UUID);
    gAdv->setScanResponse(true);
    gAdv->setMinPreferred(0x06);
    gAdv->setMinPreferred(0x12);
    gAdv->start();

    Serial.println("aupesbox advertising started");
}

void loop() {
    // ── Update TFT on connection change ──
    if (deviceConnected != oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
        tft.fillScreen(TFT_BLACK);
        tft.setCursor(0, 0);
        tft.setTextColor(deviceConnected ? TFT_GREEN : TFT_YELLOW, TFT_BLACK);
        tft.print(deviceConnected ? "Connected" : "Advertising...");
    }

    if (deviceConnected) {
        // Read orientation
        sensors_event_t evt;
        bno.getEvent(&evt);
        float rawH  = evt.orientation.x;
        float roll  = evt.orientation.y;
        float pitch = evt.orientation.z;

        // Apply zero-offset
        float adjH = rawH - zeroOffset;
        if (adjH < 0) adjH += 360.0;

        // Map to 0–255 and notify
        uint8_t rawVal = uint8_t(constrain((adjH / 360.0) * 255.0, 0.0, 255.0));
        throttleChar->setValue(&rawVal, 1);
        throttleChar->notify();

        // TFT throttle % display
        int pct = int((adjH / 360.0) * 100.0 + 0.5);
        tft.setCursor(0, 32);
        tft.setTextColor(TFT_WHITE, TFT_BLACK);
        tft.printf("Thr: %3d%%", pct);

        // TFT heading, roll, pitch
        // tft.setCursor(0, 56);
        // tft.printf("H:%3.0f R:%3.0f P:%3.0f", rawH, roll, pitch);
// Heading (0–360)/////////////////graphs
        tft.setCursor(0, 56);
        tft.setTextColor(TFT_YELLOW, TFT_BLACK);
        tft.printf("H:%3.0f", rawH);
        drawBar(60, 56, 150, 10, rawH, 0, 360, TFT_YELLOW);

// Roll (-180–180)
        tft.setCursor(0, 72);
        tft.setTextColor(TFT_CYAN, TFT_BLACK);
        tft.printf("R:%3.0f", roll);
        drawBar(60, 72, 150, 10, roll, -180, 180, TFT_CYAN);

// Pitch (-90–90)
        tft.setCursor(0, 88);
        tft.setTextColor(TFT_GREEN, TFT_BLACK);
        tft.printf("P:%3.0f", pitch);
        drawBar(60, 88, 150, 10, pitch, -90, 90, TFT_GREEN);
////////////////////////////////////////////////////////////////
        // Calibration status
        uint8_t sys, gyrC, accC, magC;
        bno.getCalibration(&sys, &gyrC, &accC, &magC);
        tft.setCursor(0, 80);
        //tft.printf("Cal S%d G%d A%d M%d", sys, gyrC, accC, magC);
    }

    // Show "Zero set!" after calibration
    if (needCalibration) {
        tft.fillScreen(TFT_BLACK);
        tft.setCursor(0, 0);
        tft.setTextColor(TFT_CYAN, TFT_BLACK);
        tft.print("Zero set!");
        delay(800);
        needCalibration = false;
    }

    delay(100);  // ~10 Hz update
}
// Draw a horizontal bar (x, y = top-left, w = max width, h = height, val = -100..100 or 0..360)
void drawBar(int x, int y, int w, int h, float val, float minVal, float maxVal, uint16_t color) {
    // Map value to 0..w
    int barLen = map((int)val, (int)minVal, (int)maxVal, 0, w);
    if (barLen < 0) barLen = 0;
    if (barLen > w) barLen = w;

    // Clear background
    tft.fillRect(x, y, w, h, TFT_BLACK);

    // Draw filled portion
    tft.fillRect(x, y, barLen, h, color);

    // Draw border
    tft.drawRect(x, y, w, h, TFT_WHITE);
}
