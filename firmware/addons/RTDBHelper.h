#ifndef RTDB_HElPER_H
#define RTDB_HElPER_H

#include <Arduino.h>
#include <Firebase_ESP_Client.h>

void printResult(FirebaseData &data) {
  if (data.dataTypeEnum() == firebase_rtdb_data_type_integer)
    Serial.println(data.to<int>());
  else if (data.dataTypeEnum() == firebase_rtdb_data_type_float)
    Serial.println(data.to<float>(), 5);
  else if (data.dataTypeEnum() == firebase_rtdb_data_type_double)
    Serial.printf("%.9lf\n", data.to<double>());
  else if (data.dataTypeEnum() == firebase_rtdb_data_type_boolean)
    Serial.println(data.to<bool>() == 1 ? "true" : "false");
  else if (data.dataTypeEnum() == firebase_rtdb_data_type_string)
    Serial.println(data.to<String>());
  else if (data.dataTypeEnum() == firebase_rtdb_data_type_json) {
    FirebaseJson *json = data.to<FirebaseJson *>();
    String jsonStr;
    json->toString(jsonStr, true);
    Serial.println(jsonStr);
  }
}

void printResult(FirebaseStream &data) {
  if (data.dataTypeEnum() == firebase_rtdb_data_type_integer)
    Serial.println(data.to<int>());
  else if (data.dataTypeEnum() == firebase_rtdb_data_type_float)
    Serial.println(data.to<float>(), 5);
  else if (data.dataTypeEnum() == firebase_rtdb_data_type_double)
    Serial.printf("%.9lf\n", data.to<double>());
  else if (data.dataTypeEnum() == firebase_rtdb_data_type_boolean)
    Serial.println(data.to<bool>() == 1 ? "true" : "false");
  else if (data.dataTypeEnum() == firebase_rtdb_data_type_string ||
           data.dataTypeEnum() == firebase_rtdb_data_type_null)
    Serial.println(data.to<String>());
}

#endif
