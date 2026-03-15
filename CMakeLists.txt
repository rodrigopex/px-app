cmake_minimum_required(VERSION 3.20.0)

set(ZEPHYR_EXTRA_MODULES "${CMAKE_CURRENT_SOURCE_DIR}/../objective-z")

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(oz_app)

target_include_directories(app PRIVATE src)

objz_transpile_sources(app
  src/main.m
  src/services/PXAppConfig.m
  src/PXSensorReading.m
  src/models/PXTemperatureSensor.m
  src/models/PXHumiditySensor.m
  src/services/PXSensorRegistry.m
  src/services/PXMovingAverageFilter.m
  src/services/PXThresholdFilter.m
  src/services/PXDeviceManager.m
  src/services/PXZbusPublisher.m
  src/services/PXLogger.m
  src/services/PXSystemStatus.m
  src/models/PXSensorBase.m
  src/models/PXAnalogSensor.m
  src/models/PXPressureSensor.m
  src/models/PXBarometer.m
  # DEV adds .m files here incrementally
)
