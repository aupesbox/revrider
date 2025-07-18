C:\Users\DELL\StudioProjects\revrider\lib\utils\BLE_Scanner\BLE_Scanner.ino:4:3: error: 'imu' does not name a type
    4 |   imu::Vector<3> accel = bno.getVector(Adafruit_BNO055::VECTOR_ACCELEROMETER);
      |   ^~~
C:\Users\DELL\StudioProjects\revrider\lib\utils\BLE_Scanner\BLE_Scanner.ino:5:3: error: 'imu' does not name a type
    5 |   imu::Vector<3> gyro  = bno.getVector(Adafruit_BNO055::VECTOR_GYROSCOPE);
      |   ^~~
C:\Users\DELL\StudioProjects\revrider\lib\utils\BLE_Scanner\BLE_Scanner.ino:6:3: error: 'imu' does not name a type
    6 |   imu::Vector<3> mag   = bno.getVector(Adafruit_BNO055::VECTOR_MAGNETOMETER);
      |   ^~~
C:\Users\DELL\StudioProjects\revrider\lib\utils\BLE_Scanner\BLE_Scanner.ino:10:3: error: 'bno' does not name a type
   10 |   bno.getCalibration(&sys, &gyrC, &accC, &magC);
      |   ^~~
In file included from C:\Users\DELL\AppData\Local\Arduino15\packages\esp32\hardware\esp32\3.2.1\cores\esp32/Arduino.h:202,
                 from C:\Users\DELL\AppData\Local\arduino\sketches\3D511F12BA78ADE9382D56FC2D748096\sketch\BLE_Scanner.ino.cpp:1:
C:\Users\DELL\AppData\Local\Arduino15\packages\esp32\hardware\esp32\3.2.1\cores\esp32/HardwareSerial.h:420:16: error: 'Serial0' does not name a type; did you mean 'Serial'?
  420 | #define Serial Serial0
      |                ^~~~~~~
C:\Users\DELL\StudioProjects\revrider\lib\utils\BLE_Scanner\BLE_Scanner.ino:15:3: note: in expansion of macro 'Serial'
   15 |   Serial.printf("Acc: %.2f, %.2f, %.2f\n",
      |   ^~~~~~
C:\Users\DELL\AppData\Local\Arduino15\packages\esp32\hardware\esp32\3.2.1\cores\esp32/HardwareSerial.h:420:16: error: 'Serial0' does not name a type; did you mean 'Serial'?
  420 | #define Serial Serial0
      |                ^~~~~~~
C:\Users\DELL\StudioProjects\revrider\lib\utils\BLE_Scanner\BLE_Scanner.ino:17:3: note: in expansion of macro 'Serial'
   17 |   Serial.printf("Gyro: %.2f, %.2f, %.2f\n",
      |   ^~~~~~
C:\Users\DELL\AppData\Local\Arduino15\packages\esp32\hardware\esp32\3.2.1\cores\esp32/HardwareSerial.h:420:16: error: 'Serial0' does not name a type; did you mean 'Serial'?
  420 | #define Serial Serial0
      |                ^~~~~~~
C:\Users\DELL\StudioProjects\revrider\lib\utils\BLE_Scanner\BLE_Scanner.ino:19:3: note: in expansion of macro 'Serial'
   19 |   Serial.printf("Mag: %.2f, %.2f, %.2f\n",
      |   ^~~~~~
C:\Users\DELL\AppData\Local\Arduino15\packages\esp32\hardware\esp32\3.2.1\cores\esp32/HardwareSerial.h:420:16: error: 'Serial0' does not name a type; did you mean 'Serial'?
  420 | #define Serial Serial0
      |                ^~~~~~~
C:\Users\DELL\StudioProjects\revrider\lib\utils\BLE_Scanner\BLE_Scanner.ino:21:3: note: in expansion of macro 'Serial'
   21 |   Serial.printf("Cal: S%d G%d A%d M%d\n\n",
      |   ^~~~~~
exit status 1

Compilation error: 'imu' does not name a type
// #include <Wire.h>
// #include <Adafruit_Sensor.h>
// #include <Adafruit_BNO055.h>
// #include <BLEDevice.h>
// #include <BLEServer.h>
// #include <BLEUtils.h>
// #include <BLE2902.h>
// #include <TFT_eSPI.h>

// // ── BLE UUIDs ────────────────────────────────────────────────────────
// #define SERVICE_UUID        "12345678-1234-5678-1234-56789abcdef0"
// #define CHAR_THROTTLE_UUID  "12345678-1234-5678-1234-56789abcdef1"
// #define CHAR_CALIBRATE_UUID "12345678-1234-5678-1234-56789abcdef2"

// // ── Hardware Objects ──────────────────────────────────────────────────
// TFT_eSPI        tft = TFT_eSPI();
// Adafruit_BNO055 bno = Adafruit_BNO055(55, 0x28);

// // ── BLE Globals ──────────────────────────────────────────────────────
// BLECharacteristic* throttleChar = nullptr;
// BLECharacteristic* calibChar    = nullptr;

// volatile bool needCalibration = false;
// bool deviceConnected          = false;
// bool oldDeviceConnected       = false;
// float zeroOffset              = 0.0;

// // ── Read heading (0–360°) from BNO055 ─────────────────────────────────
// float readHeading() {
//   sensors_event_t evt;
//   bno.getEvent(&evt);
//   // evt.orientation.x goes from 0→360 in Adafruit library
//   return evt.orientation.x;
// }

// // ── BLE Server callbacks ───────────────────────────────────────────────
// class ServerCB : public BLEServerCallbacks {
//   void onConnect(BLEServer* p)    override { deviceConnected = true; }
//   void onDisconnect(BLEServer* p) override { deviceConnected = false; }
// };

// // ── Write-to-zero callback ─────────────────────────────────────────────
// class CalibCB : public BLECharacteristicCallbacks {
//   void onWrite(BLECharacteristic* chr) override {
//     String v = chr->getValue();
//     if (v.length() && v[0] == 0x01) {
//       zeroOffset     = readHeading();
//       needCalibration = true;
//     }
//   }
// };

// void setup() {
//   Serial.begin(115200);
//   delay(500);

//   // —— TFT Init ——  
//   tft.init();
//   tft.setRotation(1);
//   tft.fillScreen(TFT_BLACK);
//   tft.setTextSize(2);
//   tft.setTextColor(TFT_YELLOW, TFT_BLACK);
//   tft.setCursor(0, 0);
//   tft.print("Advertising...");

//   // —— BNO055 Init ——  
//   if (!bno.begin()) {
//     Serial.println("BNO055 not found!");
//     while (1) delay(10);
//   }
//   bno.setExtCrystalUse(true);

//   // —— BLE Init ——  
//   BLEDevice::init("aupesbox");
//   BLEServer* server = BLEDevice::createServer();
//   server->setCallbacks(new ServerCB());

//   BLEService* svc = server->createService(SERVICE_UUID);

//   throttleChar = svc->createCharacteristic(
//     CHAR_THROTTLE_UUID,
//     BLECharacteristic::PROPERTY_NOTIFY
//   );
//   throttleChar->addDescriptor(new BLE2902());

//   calibChar = svc->createCharacteristic(
//     CHAR_CALIBRATE_UUID,
//     BLECharacteristic::PROPERTY_WRITE
//   );
//   calibChar->setCallbacks(new CalibCB());

//   svc->start();
//   BLEAdvertising* adv = server->getAdvertising();
//   adv->addServiceUUID(SERVICE_UUID);
//   adv->setScanResponse(true);
//   adv->setMinPreferred(0x06);
//   adv->setMinPreferred(0x12);
//   adv->start();
//   Serial.println("aupesbox advertising started");
// }

// void loop() {
//   // —— Update display on connect/disconnect ——  
//   if (deviceConnected != oldDeviceConnected) {
//     oldDeviceConnected = deviceConnected;
//     tft.fillScreen(TFT_BLACK);
//     tft.setCursor(0, 0);
//     tft.setTextColor(deviceConnected ? TFT_GREEN : TFT_YELLOW, TFT_BLACK);
//     tft.print(deviceConnected ? "Connected" : "Advertising...");
//   }

//   if (deviceConnected) {
//     // 1) Read & zero‐offset heading
//     float rawH = readHeading();
//     float adjH = rawH - zeroOffset;
//     if (adjH < 0) adjH += 360.0;

//     // 2) Compute raw 0–255 for BLE
//     uint8_t rawVal = uint8_t(constrain((adjH / 360.0) * 255.0, 0.0, 255.0));

//     // 3) Notify BLE central
//     throttleChar->setValue(&rawVal, 1);
//     throttleChar->notify();

//     // 4) Compute and display percent 0–100
//     int pct = int((adjH / 360.0) * 100.0 + 0.5);
//     tft.setCursor(0, 32);
//     tft.setTextColor(TFT_WHITE, TFT_BLACK);
//     tft.printf("Thr: %3d%%", pct);

//     // 5) Show Heading, Roll, Pitch
//     sensors_event_t evt;
//     bno.getEvent(&evt);
//     float roll  = evt.orientation.y;  // –180→180
//     float pitch = evt.orientation.z;  // –90→90

//     tft.setCursor(0, 56);
//     tft.printf("H:%3.0f R:%3.0f P:%3.0f", rawH, roll, pitch);

//     // 6) Show calibration status
//     uint8_t sys, gyr, acc, mag;
//     bno.getCalibration(&sys, &gyr, &acc, &mag);
//     tft.setCursor(0, 80);
//     tft.printf("Cal S%d G%d A%d M%d", sys, gyr, acc, mag);
//   }

//   // Show “Zero set!” briefly on calibration
//   if (needCalibration) {
//     tft.fillScreen(TFT_BLACK);
//     tft.setCursor(0, 0);
//     tft.setTextColor(TFT_CYAN, TFT_BLACK);
//     tft.print("Zero set!");
//     delay(800);
//     needCalibration = false;
//   }

//   delay(100);  // ~10 Hz update
// }
