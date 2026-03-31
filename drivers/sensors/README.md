# Sensors Driver Information - Galaxy S20 FE

## Hardware Sensors

Galaxy S20 FE typically includes:

| Sensor | Model | Interface |
|--------|-------|----------|
| Accelerometer | Invensense MPU6050 or similar | I2C |
| Magnetometer | Asahi Kasei AK8975 | I2C |
| Gyroscope | Integrated in MPU6050 | I2C |
| Barometer | Bosch BMP280 | I2C |
| Proximity | GP2AP002 | I2C |
| Ambient Light | ISL98611 or similar | I2C |

## Kernel Configuration

```bash
CONFIG_IIO=y                    # Industrial I/O subsystem
CONFIG_IIO_BUFFER=y
CONFIG_IIO_TRIGGERED_BUFFER=y
CONFIG_INV_MPU6050_IIO=y       # MPU6050 accelerometer/gyroscope
CONFIG_AK8975=y                  # AK8975 magnetometer
CONFIG_BMP280=y                  # BMP280 barometer
CONFIG_GP2AP002=y               # Proximity sensor
```

## Device Nodes

Sensors appear under `/sys/bus/iio/`:
```
/sys/bus/iio/devices/iio:device0  - Accelerometer
/sys/bus/iio/devices/iio:device1  - Gyroscope
/sys/bus/iio/devices/iio:device2  - Magnetometer
/sys/bus/iio/devices/iio:device3  - Barometer
```

## Reading Sensor Data

```bash
# Accelerometer
cat /sys/bus/iio/devices/iio:device0/in_accel_raw

# Gyroscope
cat /sys/bus/iio/devices/iio:device1/in_gyro_raw

# Light sensor
cat /sys/bus/iio/devices/iio:device*/in_illuminance_raw
```

## Gaming Use Cases

- **Auto-rotation**: Uses accelerometer
- **Motion controls**: Uses gyroscope
- **Ambient display**: Uses light sensor
- **Step counting**: Uses accelerometer

## Known Issues

1. **Sensors not working**: Check I2C bus: `i2cdetect -l`
2. **Wrong readings**: Sensors may need calibration
3. **High power usage**: Disable unused sensors in `/etc/steamphone/steamphone.conf`

## References

- IIO: https://www.kernel.org/doc/html/latest/driver-api/iio/index.html
- MPU6050: https://invensense.tdk.com/products/motion-tracking/6-axis/
