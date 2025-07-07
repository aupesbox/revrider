#include <BLEDevice.h>
#include <BLEScan.h>
#include <BLEAdvertisedDevice.h>
#include <TFT_eSPI.h>
#include <SPI.h>

const int scanTime = 5;  // seconds per scan
TFT_eSPI tft = TFT_eSPI();

void setup() {
  Serial.begin(115200);
  delay(1000);

  // Initialize BLE
  BLEDevice::init("");

  // Initialize the TFT display
  tft.init();
  tft.setRotation(1);         // Rotate display if needed (0-3)
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  tft.setTextSize(2);
}

void loop() {
  // Clear screen at start of each scan
  tft.fillScreen(TFT_BLACK);
  tft.drawString("Scanning BLE...", 0, 0, 2);

  // Perform BLE scan
  BLEScan* pBLEScan = BLEDevice::getScan();
  pBLEScan->setActiveScan(true);
  BLEScanResults* pResults = pBLEScan->start(scanTime, false);

  int count = pResults->getCount();
  Serial.printf("Found %d devices:\n", count);

  // Display up to 4 devices to avoid overlap
  int maxDisplay = min(count, 4);
  for (int i = 0; i < maxDisplay; i++) {
    BLEAdvertisedDevice device = pResults->getDevice(i);
    String name = device.getName().length() ? device.getName().c_str() : "<no name>";
    String line = String(i) + ":" + name + " RSSI=" + device.getRSSI();
    // Y = header height (approx 18px) + i * line height (20px)
    tft.drawString(line, 0, 35 + i*20, 1);
    Serial.println(line);
  }

  // Clean up and short delay
  pBLEScan->clearResults();
  delay(1000);
}
