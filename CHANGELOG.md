## 0.0.14

- fix discoverServices failure with clearGattCache

## 0.0.13

- Add unlock pairing write to support tethering

## 0.0.12

- Unsecured networks pass emptry string for PSK instead of `NONE`

## 0.0.11

- Throwing when can't find specific ble service or characteristic with id

## 0.0.10

- Re-write error reading to expose full list of errors

## 0.0.9

- New characteristic to write to exit provisioning
- New characteristic to read agent version

## 0.0.8

- Refactor to use extensions on `BluetoothDevice` from `flutter_blue_plus` for majority of the functionality
- `ViamBluetoothProvisioning` only uses static functions (no internal state needed for powered on tracking)

## 0.0.7

- Fix reading status

## 0.0.6

- Reading manufacturer support
- Reading model support

## 0.0.5

- Use flutter_blue_plus as the underlying dependency

## 0.0.4

- Add function for reading errors
- Password optional when writing network config

## 0.0.3

Reading public key characteristic and encoding writes

## 0.0.2

Updated blev package to 0.0.7

## 0.0.1

* Pre-launch release
